import 'package:firebase_database/firebase_database.dart';
import '../models/user_model.dart';
import '../utils/app_levels.dart';

class UserStatsService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  DatabaseReference _usersRef() => _db.child('users');

  Future<UserModel?> getUser(String uid) async {
    final snapshot = await _usersRef().child(uid).get();
    if (!snapshot.exists || snapshot.value == null) return null;

    final map = snapshot.value as Map<dynamic, dynamic>;
    return UserModel.fromMap(uid, map);
  }

  Stream<UserModel?> streamUser(String uid) {
    return _usersRef().child(uid).onValue.map((event) {
      final value = event.snapshot.value;
      if (value == null) return null;
      return UserModel.fromMap(uid, value as Map<dynamic, dynamic>);
    });
  }

  Future<void> createUserIfMissing({
    required String uid,
    required String email,
    required String displayName,
  }) async {
    final snapshot = await _usersRef().child(uid).get();

    if (snapshot.exists) return;

    final user = UserModel.empty(uid, email).copyWith(
      displayName: displayName,
    );

    await _usersRef().child(uid).set(user.toMap());
  }

  Future<void> applyApprovedSubmission({
    required String userId,
  }) async {
    final user = await getUser(userId);
    if (user == null) return;

    final today = _todayString();
    final yesterday = _yesterdayString();

    int newStreak = 1;

    if (user.lastApprovedDate == today) {
      newStreak = user.streak;
    } else if (user.lastApprovedDate == yesterday) {
      newStreak = user.streak + 1;
    } else {
      newStreak = 1;
    }

    final streakBonus = _streakBonus(newStreak);
    final xpGain = 5 + streakBonus;
    final newXp = user.xp + xpGain;
    final rankTitle = AppLevels.rankTitleFromXp(newXp);

    await _usersRef().child(userId).update({
      'xp': newXp,
      'streak': newStreak,
      'approvedProofs': user.approvedProofs + 1,
      'rankTitle': rankTitle,
      'lastApprovedDate': today,
    });
  }

  Future<void> applyApprovedChallengeWin({
    required String winnerUserId,
    required int wagerAmount,
  }) async {
    final user = await getUser(winnerUserId);
    if (user == null) return;

    final rewardCoins = wagerAmount * 2;
    final xpGain = 10;
    final newXp = user.xp + xpGain;
    final rankTitle = AppLevels.rankTitleFromXp(newXp);

    await _usersRef().child(winnerUserId).update({
      'coins': user.coins + rewardCoins,
      'xp': newXp,
      'approvedChallenges': user.approvedChallenges + 1,
      'rankTitle': rankTitle,
    });
  }

  Future<void> deductCoins({
    required String userId,
    required int amount,
  }) async {
    final user = await getUser(userId);
    if (user == null) return;

    final nextCoins = user.coins - amount;
    if (nextCoins < 0) {
      throw Exception('Insufficient coins');
    }

    await _usersRef().child(userId).update({
      'coins': nextCoins,
    });
  }

  Future<void> addCoins({
    required String userId,
    required int amount,
  }) async {
    final user = await getUser(userId);
    if (user == null) return;

    await _usersRef().child(userId).update({
      'coins': user.coins + amount,
    });
  }

  Future<List<UserModel>> getTopUsersByXp({int limit = 20}) async {
    final snapshot = await _usersRef().get();
    if (!snapshot.exists || snapshot.value == null) return [];

    final raw = snapshot.value as Map<dynamic, dynamic>;
    final users = raw.entries.map((entry) {
      return UserModel.fromMap(
        entry.key.toString(),
        entry.value as Map<dynamic, dynamic>,
      );
    }).toList();

    users.sort((a, b) => b.xp.compareTo(a.xp));
    return users.take(limit).toList();
  }

  int _streakBonus(int streak) {
    if (streak >= 30) return 15;
    if (streak >= 14) return 10;
    if (streak >= 7) return 5;
    if (streak >= 3) return 2;
    return 0;
  }

  String _todayString() {
    final now = DateTime.now();
    return _dateOnly(now);
  }

  String _yesterdayString() {
    final now = DateTime.now().subtract(const Duration(days: 1));
    return _dateOnly(now);
  }

  String _dateOnly(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}