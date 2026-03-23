import 'package:firebase_database/firebase_database.dart';

import 'user_stats_service.dart';

class SubmissionService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final UserStatsService _userStatsService = UserStatsService();

  DatabaseReference get _submissions => _db.child('submissions');
  DatabaseReference get _challenges => _db.child('challenges');

  Future<void> submitProof({
    required String userId,
    required String challengeId,
    required String imageUrl,
  }) async {
    final now = DateTime.now();
    final today = _dateOnly(now);

    final challengeData = await _getChallengeData(challengeId);

    final String challengeStatus =
        (challengeData['status'] ?? '').toString().trim().toLowerCase();

    final DateTime startDate = _parseDate(
      challengeData['startDate'],
      fieldName: 'startDate',
    );
    final DateTime endDate = _parseDate(
      challengeData['endDate'],
      fieldName: 'endDate',
    );

    if (challengeStatus.isNotEmpty &&
        challengeStatus != 'active' &&
        challengeStatus != 'pending') {
      throw Exception('This challenge is not accepting submissions.');
    }

    if (now.isBefore(startDate)) {
      throw Exception('This challenge has not started yet.');
    }

    if (now.isAfter(endDate)) {
      throw Exception('This challenge has already ended.');
    }

    final existingSubmissions = await _getUserSubmissions(userId);

    for (final submission in existingSubmissions) {
      final String existingChallengeId =
          (submission['challengeId'] ?? '').toString();
      final String status =
          (submission['status'] ?? '').toString().trim().toLowerCase();
      final String submittedDate =
          (submission['submittedDate'] ?? '').toString().trim();

      if (existingChallengeId != challengeId) {
        continue;
      }

      if (status == 'pending' || status == 'approved') {
        throw Exception(
          'You have already submitted proof for this challenge.',
        );
      }

      if (submittedDate == today) {
        throw Exception('You already submitted proof today.');
      }
    }

    final DatabaseReference newRef = _submissions.push();

    await newRef.set({
      'submissionId': newRef.key,
      'userId': userId,
      'challengeId': challengeId,
      'imageUrl': imageUrl,
      'submittedAt': now.toIso8601String(),
      'submittedDate': today,
      'status': 'pending',
      'reviewedAt': null,
      'reviewNote': null,
    });
  }

  Future<List<Map<String, dynamic>>> getPendingSubmissions() async {
    return _getSubmissionsByStatus('pending');
  }

  Future<void> approveSubmission({
    required String submissionId,
  }) async {
    final DatabaseReference subRef = _submissions.child(submissionId);
    final DataSnapshot subSnap = await subRef.get();

    if (!subSnap.exists || subSnap.value == null) {
      throw Exception('Submission not found.');
    }

    final Map<String, dynamic> sub = _asMap(subSnap.value);

    if ((sub['status'] ?? '').toString().trim().toLowerCase() != 'pending') {
      throw Exception('Submission already reviewed.');
    }

    final String userId = (sub['userId'] ?? '').toString().trim();
    if (userId.isEmpty) {
      throw Exception('Submission has no userId.');
    }

    await subRef.update({
      'status': 'approved',
      'reviewedAt': DateTime.now().toIso8601String(),
      'reviewNote': 'Approved by admin',
    });

    await _userStatsService.applyApprovedSubmission(userId: userId);
  }

  Future<void> rejectSubmission({
    required String submissionId,
    String? reason,
  }) async {
    final DatabaseReference subRef = _submissions.child(submissionId);
    final DataSnapshot subSnap = await subRef.get();

    if (!subSnap.exists || subSnap.value == null) {
      throw Exception('Submission not found.');
    }

    final Map<String, dynamic> sub = _asMap(subSnap.value);

    if ((sub['status'] ?? '').toString().trim().toLowerCase() != 'pending') {
      throw Exception('Submission already reviewed.');
    }

    await subRef.update({
      'status': 'rejected',
      'reviewedAt': DateTime.now().toIso8601String(),
      'reviewNote': reason?.trim().isNotEmpty == true
          ? reason!.trim()
          : 'Rejected by admin',
    });
  }

  Future<List<Map<String, dynamic>>> getApprovedSubmissions() async {
    return _getSubmissionsByStatus('approved');
  }

  Future<List<Map<String, dynamic>>> getRejectedSubmissions() async {
    return _getSubmissionsByStatus('rejected');
  }

  Future<bool> hasActiveSubmissionForChallenge({
    required String userId,
    required String challengeId,
  }) async {
    final submissions = await _getUserSubmissions(userId);

    for (final submission in submissions) {
      final String existingChallengeId =
          (submission['challengeId'] ?? '').toString();
      final String status =
          (submission['status'] ?? '').toString().trim().toLowerCase();

      if (existingChallengeId == challengeId &&
          (status == 'pending' || status == 'approved')) {
        return true;
      }
    }

    return false;
  }

  Future<Map<String, dynamic>> _getChallengeData(String challengeId) async {
    final DataSnapshot challengeSnap = await _challenges.child(challengeId).get();

    if (!challengeSnap.exists || challengeSnap.value == null) {
      throw Exception('Challenge not found.');
    }

    return _asMap(challengeSnap.value);
  }

  Future<List<Map<String, dynamic>>> _getUserSubmissions(String userId) async {
    final DataSnapshot snapshot =
        await _submissions.orderByChild('userId').equalTo(userId).get();

    if (!snapshot.exists || snapshot.value == null) {
      return [];
    }

    final Map<String, dynamic> raw = _asMap(snapshot.value);
    final List<Map<String, dynamic>> submissions = [];

    for (final entry in raw.entries) {
      final Map<String, dynamic> value = _asMap(entry.value);

      submissions.add({
        'submissionId': entry.key,
        ...value,
      });
    }

    return submissions;
  }

  Future<List<Map<String, dynamic>>> _getSubmissionsByStatus(
    String targetStatus,
  ) async {
    final DataSnapshot snapshot = await _submissions.get();

    if (!snapshot.exists || snapshot.value == null) {
      return [];
    }

    final Map<String, dynamic> raw = _asMap(snapshot.value);
    final List<Map<String, dynamic>> results = [];

    for (final entry in raw.entries) {
      final Map<String, dynamic> value = _asMap(entry.value);
      final String status =
          (value['status'] ?? '').toString().trim().toLowerCase();

      if (status == targetStatus) {
        results.add({
          'submissionId': entry.key.toString(),
          'userId': (value['userId'] ?? '').toString(),
          'challengeId': (value['challengeId'] ?? '').toString(),
          'imageUrl': (value['imageUrl'] ?? '').toString(),
          'submittedAt': (value['submittedAt'] ?? '').toString(),
          'submittedDate': (value['submittedDate'] ?? '').toString(),
          'reviewedAt': (value['reviewedAt'] ?? '').toString(),
          'reviewNote': (value['reviewNote'] ?? '').toString(),
          'status': status,
        });
      }
    }

    results.sort((a, b) {
      final String aTime = a['submittedAt']?.toString() ?? '';
      final String bTime = b['submittedAt']?.toString() ?? '';
      return bTime.compareTo(aTime);
    });

    return results;
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map) {
      return value.map(
        (key, val) => MapEntry(key.toString(), val),
      );
    }
    return <String, dynamic>{};
  }

  DateTime _parseDate(
    dynamic rawDate, {
    required String fieldName,
  }) {
    if (rawDate == null) {
      throw Exception('Challenge $fieldName is missing.');
    }

    try {
      return DateTime.parse(rawDate.toString());
    } catch (_) {
      throw Exception('Challenge $fieldName is invalid.');
    }
  }

  String _dateOnly(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}