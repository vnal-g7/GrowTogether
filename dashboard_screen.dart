import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../models/user_model.dart';
import '../services/user_stats_service.dart';
import '../utils/app_levels.dart';
import 'coin_game_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final UserStatsService _userStatsService = UserStatsService();

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  Stream<int> _rankStream(String uid) async* {
    while (true) {
      try {
        final users = await _userStatsService.getTopUsersByXp(limit: 500);
        final index = users.indexWhere((u) => u.uid == uid);
        yield index == -1 ? 0 : index + 1;
      } catch (e) {
        debugPrint('Rank stream error: $e');
        yield 0;
      }

      await Future.delayed(const Duration(seconds: 5));
    }
  }

  Widget _buildMiniStat(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1D2747),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            letterSpacing: 1.2,
            color: Colors.blueGrey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color iconBg = const Color(0xFFE8EDFF),
    Color iconColor = const Color(0xFF3D5AFE),
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E1E1E)
              : Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                Theme.of(context).brightness == Brightness.dark ? 0.25 : 0.04,
              ),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : const Color(0xFF1D2747),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firebaseUser = _auth.currentUser;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    if (firebaseUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF3D5AFE),
              ),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.person,
                  size: 40,
                  color: Color(0xFF3D5AFE),
                ),
              ),
              accountName: Text(
                firebaseUser.displayName?.trim().isNotEmpty == true
                    ? firebaseUser.displayName!.trim()
                    : 'User',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(firebaseUser.email ?? ''),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text('Dashboard'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.leaderboard_outlined),
              title: const Text('Leaderboard'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/leaderboard');
              },
            ),
            ListTile(
              leading: const Icon(Icons.task_alt_outlined),
              title: const Text('Challenges'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/challenges');
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/edit-profile');
              },
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Sign Out',
                style: TextStyle(color: Colors.red),
              ),
              onTap: _signOut,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        leading: IconButton(
          icon: Icon(
            Icons.menu,
            color: isDark ? Colors.white : const Color(0xFF1D2747),
          ),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text(
          'GrowTogether',
          style: TextStyle(
            color: Color(0xFF3D5AFE),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Icon(
            isDark ? Icons.dark_mode : Icons.light_mode,
            color: isDark ? Colors.orangeAccent : Colors.blueGrey,
            size: 20,
          ),
          Switch(
            value: isDark,
            onChanged: (bool value) {
              themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
            },
          ),
          IconButton(
            icon: Icon(
              Icons.account_circle_outlined,
              color: isDark ? Colors.white : const Color(0xFF1D2747),
            ),
            onPressed: () => Navigator.pushNamed(context, '/edit-profile'),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: StreamBuilder<UserModel?>(
        stream: _userStatsService.streamUser(firebaseUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data;

          if (user == null) {
            return const Center(child: Text('User data not found'));
          }

          final displayName =
              user.displayName.trim().isNotEmpty ? user.displayName.trim() : 'User';

          final level = AppLevels.levelFromXp(user.xp);
          final progress = AppLevels.progressToNextLevel(user.xp);
          final nextXp = AppLevels.xpForNextLevel(user.xp);
          final xpNeeded = (nextXp - user.xp).clamp(0, 999999);
          final tierLabel = user.rankTitle ?? 'Beginner';
          final activityStatus = user.streak > 0 ? 'Active' : 'Starting';

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      'Hello, $displayName!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1D2747),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Ready for your daily growth?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blueGrey,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.30 : 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.orange.withOpacity(0.1),
                            child: const Icon(
                              Icons.monetization_on,
                              color: Colors.orange,
                              size: 50,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Text(
                            '${user.coins}',
                            style: TextStyle(
                              fontSize: 60,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1D2747),
                            ),
                          ),
                          const Text(
                            'COINS BALANCE',
                            style: TextStyle(
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey,
                              fontSize: 12,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Divider(),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              StreamBuilder<int>(
                                stream: _rankStream(firebaseUser.uid),
                                builder: (context, rankSnapshot) {
                                  final rankText = rankSnapshot.hasData &&
                                          rankSnapshot.data != null &&
                                          rankSnapshot.data! > 0
                                      ? '#${rankSnapshot.data}'
                                      : '--';
                                  return _buildMiniStat(rankText, 'RANK');
                                },
                              ),
                              _buildMiniStat('${user.streak} Days', 'STREAK'),
                              _buildMiniStat('Lv $level', 'LEVEL'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'XP Progress',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1D2747),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: level >= 10 ? 1 : progress,
                              minHeight: 10,
                              backgroundColor:
                                  isDark ? Colors.grey[800] : Colors.grey[300],
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF3D5AFE),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            level >= 10
                                ? 'Maximum level reached'
                                : '$xpNeeded XP needed for next level',
                            style: const TextStyle(
                              color: Colors.blueGrey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionCard(
                            context: context,
                            icon: Icons.workspace_premium_outlined,
                            title: tierLabel,
                            subtitle: 'Current rank title',
                            onTap: () {},
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildActionCard(
                            context: context,
                            icon: Icons.local_fire_department_outlined,
                            title: activityStatus,
                            subtitle: 'Activity status',
                            onTap: () {},
                            iconBg: const Color(0xFFFFF0E5),
                            iconColor: Colors.deepOrange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildActionCard(
                      context: context,
                      icon: Icons.task_alt_outlined,
                      title: 'Challenges',
                      subtitle: 'Join and complete active challenges',
                      onTap: () => Navigator.pushNamed(context, '/challenges'),
                    ),
                    const SizedBox(height: 16),
                    _buildActionCard(
                      context: context,
                      icon: Icons.leaderboard_outlined,
                      title: 'Leaderboard',
                      subtitle: 'See how you rank against others',
                      onTap: () => Navigator.pushNamed(context, '/leaderboard'),
                    ),
                    const SizedBox(height: 16),
                    _buildActionCard(
                      context: context,
                      icon: Icons.sports_esports_outlined,
                      title: 'Coin Game',
                      subtitle: 'Play and earn more coins',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CoinGameScreen(),
                          ),
                        );
                      },
                      iconBg: const Color(0xFFEAFBF0),
                      iconColor: Colors.green,
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}