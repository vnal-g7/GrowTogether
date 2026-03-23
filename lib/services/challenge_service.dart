import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import '../core/app_utils.dart';
import '../models/challenge_model.dart';
import '../models/submission_model.dart';
import '../models/user_model.dart';
import '../utils/firebase_value_utils.dart';

class ChallengeService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<DatabaseEvent> challengesStream() => _dbRef.child('challenges').onValue;

  Stream<DatabaseEvent> userStream(String uid) =>
      _dbRef.child('users').child(uid).onValue;

  Stream<DatabaseEvent> usersStream() => _dbRef.child('users').onValue;

  Stream<DatabaseEvent> notificationsStream(String uid) {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null || currentUid != uid) {
      throw Exception('You are not allowed to access these notifications.');
    }

    return _dbRef.child('notifications').child(uid).onValue;
  }

  Stream<DatabaseEvent> unreadNotificationsStream(String uid) {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null || currentUid != uid) {
      throw Exception('You are not allowed to access these notifications.');
    }

    return _dbRef
        .child('notifications')
        .child(uid)
        .orderByChild('isRead')
        .equalTo(false)
        .onValue;
  }

  Stream<DatabaseEvent> pendingSubmissionsStream() {
    return _dbRef
        .child('submissions')
        .orderByChild('status')
        .equalTo('pending')
        .onValue;
  }

  Future<bool> isAdmin(String uid) async {
    final snapshot =
        await _dbRef.child('users').child(uid).child('isAdmin').get();
    return snapshot.value == true;
  }

  Future<UserModel?> getCurrentUserProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final snapshot = await _dbRef.child('users').child(uid).get();
    if (!snapshot.exists || snapshot.value == null) return null;

    return UserModel.fromMap(
      uid,
      FirebaseValueUtils.asMap(snapshot.value),
    );
  }

  Future<void> createChallenge({
    required String title,
    required String description,
    required int points,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    await _requireAdmin();

    final normalizedStartDate = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );

    final normalizedEndDate = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
      23,
      59,
      59,
    );

    final status = _determineChallengeStatus(
      startDate: normalizedStartDate,
      endDate: normalizedEndDate,
    );

    final challenge = ChallengeModel(
      id: '',
      title: title.trim(),
      description: description.trim(),
      points: points,
      requiresCamera: true,
      status: status,
      startDate: _formatDate(normalizedStartDate),
      endDate: _formatDate(normalizedEndDate),
      createdAt: DateTime.now().millisecondsSinceEpoch,
      winnerUserId: null,
      winnerName: null,
    );

    await _dbRef.child('challenges').push().set(challenge.toMap());
  }

  Future<void> deleteChallenge(String challengeId) async {
    await _requireAdmin();

    if (challengeId.trim().isEmpty) {
      throw Exception('Invalid challenge ID.');
    }

    await _dbRef.child('challenges').child(challengeId).remove();
  }

  Future<void> refreshChallengeStatuses() async {
    final snapshot = await _dbRef.child('challenges').get();

    if (!snapshot.exists || snapshot.value == null) return;

    final map = FirebaseValueUtils.asMap(snapshot.value);

    for (final entry in map.entries) {
      final challengeId = entry.key.toString();
      final challengeData = FirebaseValueUtils.asMap(entry.value);
      final challenge = ChallengeModel.fromMap(challengeId, challengeData);

      if (challenge.status == 'completed') {
        continue;
      }

      final startDate = _parseDate(challenge.startDate);
      final endDate = _parseDate(challenge.endDate, endOfDay: true);

      if (startDate == null || endDate == null) continue;

      final newStatus = _determineChallengeStatus(
        startDate: startDate,
        endDate: endDate,
      );

      if (newStatus != challenge.status) {
        await _dbRef.child('challenges').child(challengeId).update({
          'status': newStatus,
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> getApprovedSubmissionsForChallenge(
    String challengeId,
  ) async {
    await _requireAdmin();

    final snapshot = await _dbRef
        .child('submissions')
        .orderByChild('challengeId')
        .equalTo(challengeId)
        .get();

    if (!snapshot.exists || snapshot.value == null) {
      return [];
    }

    final map = FirebaseValueUtils.asMap(snapshot.value);
    final List<Map<String, dynamic>> approved = [];

    for (final entry in map.entries) {
      final item = FirebaseValueUtils.asMap(entry.value);
      final status = FirebaseValueUtils.asString(
        item['status'],
        fallback: 'pending',
      );

      if (status == 'approved') {
        approved.add({
          'submissionId': entry.key.toString(),
          'userId': FirebaseValueUtils.asString(item['userId']),
          'userName': FirebaseValueUtils.asString(
            item['userName'],
            fallback: 'Unknown',
          ),
          'imageUrl': FirebaseValueUtils.asString(item['imageUrl']),
          'submittedDate': FirebaseValueUtils.asString(item['submittedDate']),
          'points': FirebaseValueUtils.asInt(item['points']),
          'challengeTitle': FirebaseValueUtils.asString(item['challengeTitle']),
        });
      }
    }

    approved.sort((a, b) {
      final aDate = FirebaseValueUtils.asString(a['submittedDate']);
      final bDate = FirebaseValueUtils.asString(b['submittedDate']);
      return bDate.compareTo(aDate);
    });

    return approved;
  }

  Future<void> completeChallenge({
    required String challengeId,
    required String winnerUserId,
    required String winnerName,
  }) async {
    await _requireAdmin();

    final challengeSnapshot =
        await _dbRef.child('challenges').child(challengeId).get();

    if (!challengeSnapshot.exists || challengeSnapshot.value == null) {
      throw Exception('Challenge not found.');
    }

    final challenge = ChallengeModel.fromMap(
      challengeId,
      FirebaseValueUtils.asMap(challengeSnapshot.value),
    );

    if (challenge.status == 'completed') {
      throw Exception('This challenge is already completed.');
    }

    final approvedSubmissions =
        await getApprovedSubmissionsForChallenge(challengeId);

    final winnerHasApprovedSubmission = approvedSubmissions.any(
      (item) => item['userId'] == winnerUserId,
    );

    if (!winnerHasApprovedSubmission) {
      throw Exception('Winner must have an approved submission.');
    }

    await _dbRef.child('challenges').child(challengeId).update({
      'status': 'completed',
      'winnerUserId': winnerUserId,
      'winnerName': winnerName,
    });

    await _sendNotification(
      uid: winnerUserId,
      title: 'You Won a Challenge! 🏆',
      body:
          'Congratulations! You were selected as the winner of "${challenge.title}".',
    );
  }

  Future<void> markNotificationAsRead({
    required String uid,
    required String notificationId,
  }) async {
    final currentUid = _requireAuthenticatedUser();

    if (currentUid != uid) {
      throw Exception('You are not allowed to modify these notifications.');
    }

    await _dbRef
        .child('notifications')
        .child(uid)
        .child(notificationId)
        .update({'isRead': true});
  }

  Future<void> markAllNotificationsAsRead(String uid) async {
    final currentUid = _requireAuthenticatedUser();

    if (currentUid != uid) {
      throw Exception('You are not allowed to modify these notifications.');
    }

    final snapshot = await _dbRef.child('notifications').child(uid).get();

    if (!snapshot.exists || snapshot.value == null) return;

    final map = FirebaseValueUtils.asMap(snapshot.value);
    final Map<String, dynamic> updates = {};

    for (final entry in map.entries) {
      final id = entry.key.toString();
      final item = FirebaseValueUtils.asMap(entry.value);
      if (item['isRead'] != true) {
        updates['$id/isRead'] = true;
      }
    }

    if (updates.isNotEmpty) {
      await _dbRef.child('notifications').child(uid).update(updates);
    }
  }

  Future<bool> hasPendingSubmissionToday({
    required String userId,
    required String challengeId,
  }) async {
    final snapshot = await _dbRef
        .child('submissions')
        .orderByChild('challengeId')
        .equalTo(challengeId)
        .get();

    if (!snapshot.exists || snapshot.value == null) return false;

    final map = FirebaseValueUtils.asMap(snapshot.value);
    final today = AppUtils.todayKey();

    for (final entry in map.entries) {
      final item = FirebaseValueUtils.asMap(entry.value);
      if (FirebaseValueUtils.asString(item['userId']) == userId &&
          FirebaseValueUtils.asString(item['submittedDate']) == today &&
          FirebaseValueUtils.asString(item['status']) == 'pending') {
        return true;
      }
    }
    return false;
  }

  Future<void> submitProof({
    required String challengeId,
    required String challengeTitle,
    required int points,
    required String imageUrl,
  }) async {
    final uid = _requireAuthenticatedUser();

    await refreshChallengeStatuses();

    final challengeSnapshot =
        await _dbRef.child('challenges').child(challengeId).get();

    if (!challengeSnapshot.exists || challengeSnapshot.value == null) {
      throw Exception('Challenge not found.');
    }

    final challenge = ChallengeModel.fromMap(
      challengeId,
      FirebaseValueUtils.asMap(challengeSnapshot.value),
    );

    if (challenge.status != 'active') {
      throw Exception('This challenge is not active right now.');
    }

    final alreadySubmitted = await hasPendingSubmissionToday(
      userId: uid,
      challengeId: challengeId,
    );

    if (alreadySubmitted) {
      throw Exception('You already submitted this challenge today.');
    }

    final userSnapshot = await _dbRef.child('users').child(uid).get();
    if (!userSnapshot.exists || userSnapshot.value == null) {
      throw Exception('User profile not found.');
    }

    final userData = FirebaseValueUtils.asMap(userSnapshot.value);
    final submissionRef = _dbRef.child('submissions').push();

    final submission = SubmissionModel(
      id: submissionRef.key ?? '',
      userId: uid,
      userName: FirebaseValueUtils.asString(
        userData['name'],
        fallback: 'User',
      ),
      challengeId: challengeId,
      challengeTitle: challengeTitle,
      points: points,
      status: 'pending',
      imageUrl: imageUrl,
      submittedAt: DateTime.now().millisecondsSinceEpoch,
      cameraOnly: true,
      submittedDate: AppUtils.todayKey(),
      platform: kIsWeb ? 'web' : Platform.operatingSystem,
    );

    await submissionRef.set(submission.toMap());
  }

  Future<void> approveSubmission(
    String submissionId,
    SubmissionModel submission,
  ) async {
    await _requireAdmin();

    final submissionSnapshot =
        await _dbRef.child('submissions').child(submissionId).get();

    if (!submissionSnapshot.exists || submissionSnapshot.value == null) {
      throw Exception('Submission not found.');
    }

    final latestSubmission = SubmissionModel.fromMap(
      submissionId,
      FirebaseValueUtils.asMap(submissionSnapshot.value),
    );

    if (latestSubmission.status != 'pending') {
      throw Exception('Only pending submissions can be approved.');
    }

    final userRef = _dbRef.child('users').child(latestSubmission.userId);
    final snapshot = await userRef.get();

    if (!snapshot.exists || snapshot.value == null) {
      throw Exception('User not found.');
    }

    final user = UserModel.fromMap(
      latestSubmission.userId,
      FirebaseValueUtils.asMap(snapshot.value),
    );

    final newApprovedSubmissions = user.approvedProofs + 1;
    final newApprovedChallenges = user.approvedChallenges + 1;

    int newStreak = 1;
    final today = AppUtils.todayKey();

    if (user.lastApprovedDate == today) {
      newStreak = user.streak;
    } else if (_isYesterday(user.lastApprovedDate)) {
      newStreak = user.streak + 1;
    }

    final newXp = AppUtils.calculateXp(
      approvedChallenges: newApprovedChallenges,
      approvedSubmissions: newApprovedSubmissions,
      streak: newStreak,
    );

    await userRef.update({
      'coins': user.coins + latestSubmission.points,
      'approvedSubmissions': newApprovedSubmissions,
      'approvedChallenges': newApprovedChallenges,
      'streak': newStreak,
      'lastApprovedDate': today,
      'xp': newXp,
    });

    await _dbRef
        .child('submissions')
        .child(submissionId)
        .update({'status': 'approved'});

    await _sendNotification(
      uid: latestSubmission.userId,
      title: 'Submission Approved! 🎉',
      body:
          'Your proof for "${latestSubmission.challengeTitle}" was approved. You earned ${latestSubmission.points} coins and your streak is now $newStreak.',
    );
  }

  Future<void> rejectSubmission(
    String submissionId,
    SubmissionModel submission,
  ) async {
    await _requireAdmin();

    final submissionSnapshot =
        await _dbRef.child('submissions').child(submissionId).get();

    if (!submissionSnapshot.exists || submissionSnapshot.value == null) {
      throw Exception('Submission not found.');
    }

    final latestSubmission = SubmissionModel.fromMap(
      submissionId,
      FirebaseValueUtils.asMap(submissionSnapshot.value),
    );

    if (latestSubmission.status != 'pending') {
      throw Exception('Only pending submissions can be rejected.');
    }

    await _dbRef
        .child('submissions')
        .child(submissionId)
        .update({'status': 'rejected'});

    await _sendNotification(
      uid: latestSubmission.userId,
      title: 'Submission Rejected ❌',
      body:
          'Your proof for "${latestSubmission.challengeTitle}" was rejected. Capture a clearer live photo and try again.',
    );
  }

  Future<void> updateProfile({
    required String uid,
    required String name,
    required int? age,
    required String profilePic,
  }) async {
    final currentUid = _requireAuthenticatedUser();

    if (currentUid != uid) {
      throw Exception('You are not allowed to edit this profile.');
    }

    await _dbRef.child('users').child(uid).update({
      'name': name.trim(),
      'age': age,
      'profilePic': profilePic.trim(),
    });
  }

  Future<void> _sendNotification({
    required String uid,
    required String title,
    required String body,
  }) {
    return _dbRef.child('notifications').child(uid).push().set({
      'title': title,
      'body': body,
      'timestamp': ServerValue.timestamp,
      'isRead': false,
    });
  }

  String _requireAuthenticatedUser() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('Not authenticated.');
    }
    return uid;
  }

  Future<void> _requireAdmin() async {
    final uid = _requireAuthenticatedUser();
    final admin = await isAdmin(uid);
    if (!admin) {
      throw Exception('Admin access required.');
    }
  }

  String _determineChallengeStatus({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final now = DateTime.now();

    if (now.isBefore(startDate)) {
      return 'pending';
    }

    if (now.isAfter(endDate)) {
      return 'expired';
    }

    return 'active';
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  DateTime? _parseDate(String value, {bool endOfDay = false}) {
    try {
      final parsed = DateTime.parse(value);
      if (endOfDay) {
        return DateTime(
          parsed.year,
          parsed.month,
          parsed.day,
          23,
          59,
          59,
        );
      }
      return DateTime(parsed.year, parsed.month, parsed.day);
    } catch (_) {
      return null;
    }
  }

  bool _isYesterday(String? dateKey) {
    if (dateKey == null || dateKey.isEmpty) return false;

    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final formatted = '${yesterday.year.toString().padLeft(4, '0')}-'
        '${yesterday.month.toString().padLeft(2, '0')}-'
        '${yesterday.day.toString().padLeft(2, '0')}';

    return dateKey == formatted;
  }
}