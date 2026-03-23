import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../models/user_model.dart';
import '../services/user_stats_service.dart';
import '../utils/app_levels.dart';
import 'coin_game_screen.dart'; // 

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

  Stream<int> _rankStream(String uid) {
    return _userStatsService.streamUser(uid).asyncMap((_) async {
      final users = await _userStatsService.getTopUsersByXp(limit: 500);
      final index = users.indexWhere((u) => u.uid == uid);
      return index == -1 ? 0 : index + 1;
    });
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
        child: StreamBuilder<UserModel?>(
          stream: _userStatsService.streamUser(firebaseUser.uid),
          builder: (context, snapshot) {
            final user = snapshot.data;

            final displayName = (user?.displayName.trim().isNotEmpty ?? false)
                ? user!.displayName.trim()
                : 'User';

            final photoUrl = user?.photoUrl;

            return Column(
              children: [
                UserAccountsDrawerHeader(
                  decoration: const BoxDecoration(
                    color: Color(0xFF3D5AFE),
                  ),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.white,
                    backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                        ? NetworkImage(photoUrl)
                        : null,
                    child: (photoUrl == null || photoUrl.isEmpty)
                        ? const Icon(
                            Icons.person,
                            size: 40,
                            color: Color(0xFF3D5AFE),
                          )
                        : null,
                  ),
                  accountName: Text(
                    displayName,
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
            );
          },
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
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 30),

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

                    const SizedBox(height: 30),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3D5AFE),
                        minimumSize: const Size(double.infinity, 65),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () => Navigator.pushNamed(context, '/challenges'),
                      child: const Text(
                        'VIEW CHALLENGES',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFF3D5AFE),
                          width: 2,
                        ),
                        backgroundColor:
                            isDark ? Colors.transparent : Colors.white,
                        minimumSize: const Size(double.infinity, 60),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () => Navigator.pushNamed(context, '/leaderboard'),
                      child: const Text(
                        'VIEW LEADERBOARD',
                        style: TextStyle(
                          color: Color(0xFF3D5AFE),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // ✅ NEW BUTTON (FULLY INTEGRATED)
                    const SizedBox(height: 15),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        minimumSize: const Size(double.infinity, 65),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CoinGameScreen(),
                          ),
                        );
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.casino, color: Colors.white),
                          SizedBox(width: 10),
                          Text(
                            'PLAY LUCKY REWARD',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    _buildStatusBadge(
                      Icons.workspace_premium,
                      tierLabel,
                      'Tier Level',
                      isDark
                          ? Colors.indigo.withOpacity(0.2)
                          : const Color(0xFFE8EAF6),
                      const Color(0xFF3D5AFE),
                    ),

                    const SizedBox(height: 15),

                    _buildStatusBadge(
                      Icons.local_fire_department,
                      activityStatus,
                      'Status',
                      isDark
                          ? Colors.orange.withOpacity(0.2)
                          : const Color(0xFFFFF3E0),
                      Colors.orange,
                    ),

                    const SizedBox(height: 15),

                    _buildStatusBadge(
                      Icons.verified,
                      '${user.approvedProofs}',
                      'Approved Proofs',
                      isDark
                          ? Colors.green.withOpacity(0.2)
                          : const Color(0xFFE8F5E9),
                      Colors.green,
                    ),

                    const SizedBox(height: 15),

                    _buildStatusBadge(
                      Icons.flash_on,
                      '${user.xp}',
                      'Total XP',
                      isDark
                          ? Colors.amber.withOpacity(0.2)
                          : const Color(0xFFFFF8E1),
                      Colors.amber,
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMiniStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF3D5AFE),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.blueGrey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(
    IconData icon,
    String title,
    String subtitle,
    Color bgColor,
    Color iconColor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 15),
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}