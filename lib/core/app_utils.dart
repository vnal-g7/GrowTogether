import 'package:flutter/material.dart';

class AppUtils {
  static String todayKey() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  static int calculateXp({
    required int approvedChallenges,
    required int approvedSubmissions,
    required int streak,
  }) {
    return (approvedChallenges * 10) + (approvedSubmissions * 5) + (streak * 2);
  }

  static int levelFromXp(int xp) => (xp ~/ 100) + 1;

  static String rankTitleFromXp(int xp) {
    if (xp >= 1000) return 'Pioneer';
    if (xp >= 700) return 'Elite';
    if (xp >= 400) return 'Consistent';
    if (xp >= 150) return 'Rising Star';
    return 'Beginner';
  }

  static void showSnack(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
}
