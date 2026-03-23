import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/coin_game_result.dart';

class CoinGameService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Random _random = Random();

  static const int playCost = 20;
  static const int maxDailyPlays = 3;

  Future<CoinGameResult> playGame() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('You must be logged in.');
    }

    final String uid = user.uid;

    final userRef = _db.child('users').child(uid);
    final gameRef = _db.child('coinGames').child(uid);

    final userSnap = await userRef.get();
    if (!userSnap.exists || userSnap.value == null) {
      throw Exception('User profile not found.');
    }

    final userData = Map<dynamic, dynamic>.from(userSnap.value as Map);
    final int currentCoins = _toInt(userData['coins']);

    if (currentCoins < playCost) {
      throw Exception('Not enough coins to play.');
    }

    final gameSnap = await gameRef.get();
    int playsToday = 0;
    String? lastPlayedDate;

    if (gameSnap.exists && gameSnap.value != null) {
      final gameData = Map<dynamic, dynamic>.from(gameSnap.value as Map);
      playsToday = _toInt(gameData['playsToday']);
      lastPlayedDate = gameData['lastPlayedDate']?.toString();
    }

    final String today = _dateOnly(DateTime.now());

    if (lastPlayedDate != today) {
      playsToday = 0;
    }

    if (playsToday >= maxDailyPlays) {
      throw Exception('Daily play limit reached.');
    }

    final CoinGameResult result = _rollOutcome();

    final int totalCoinChange = result.coinChange - playCost;
    final int updatedCoins = currentCoins + totalCoinChange;
    final int currentXp = _toInt(userData['xp']);
    final int updatedXp = currentXp + result.xpChange;

    await userRef.update({
      'coins': updatedCoins < 0 ? 0 : updatedCoins,
      'xp': updatedXp < 0 ? 0 : updatedXp,
    });

    await gameRef.update({
      'lastPlayedAt': DateTime.now().toIso8601String(),
      'lastPlayedDate': today,
      'playsToday': playsToday + 1,
    });

    await _db.child('coinGameHistory').push().set({
      'userId': uid,
      'label': result.label,
      'coinChange': totalCoinChange,
      'rawReward': result.coinChange,
      'xpChange': result.xpChange,
      'cost': playCost,
      'playedAt': DateTime.now().toIso8601String(),
    });

    return CoinGameResult(
      label: result.label,
      coinChange: totalCoinChange,
      xpChange: result.xpChange,
    );
  }

  CoinGameResult _rollOutcome() {
    final int roll = _random.nextInt(100);

    if (roll < 40) {
      return const CoinGameResult(
        label: 'No luck this time',
        coinChange: 0,
        xpChange: 0,
      );
    } else if (roll < 65) {
      return const CoinGameResult(
        label: 'Small reward',
        coinChange: 10,
        xpChange: 5,
      );
    } else if (roll < 85) {
      return const CoinGameResult(
        label: 'Nice win',
        coinChange: 25,
        xpChange: 10,
      );
    } else if (roll < 95) {
      return const CoinGameResult(
        label: 'Big win',
        coinChange: 50,
        xpChange: 20,
      );
    } else {
      return const CoinGameResult(
        label: 'Jackpot boost',
        coinChange: 80,
        xpChange: 30,
      );
    }
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value?.toString() ?? '0') ?? 0;
  }

  String _dateOnly(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}