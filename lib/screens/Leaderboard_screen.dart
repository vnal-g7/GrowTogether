import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../widgets/state_widgets.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dbRef = FirebaseDatabase.instance.ref().child('users');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        centerTitle: true,
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: dbRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingState(
              title: 'Loading leaderboard...',
              subtitle: 'Ranking users by XP, coins, and approved challenges.',
            );
          }

          if (snapshot.hasError) {
            return AppErrorState(
              message: 'The leaderboard failed to load. Check your connection and try again.',
              onRetry: () {},
            );
          }

          if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
            return const AppEmptyState(
              icon: Icons.emoji_events_outlined,
              title: 'No leaderboard data yet',
              subtitle:
                  'Once users earn XP and complete challenges, rankings will appear here.',
            );
          }

          final rawMap = Map<dynamic, dynamic>.from(
            snapshot.data!.snapshot.value as Map,
          );

          final users = rawMap.entries.map((entry) {
            final data = Map<dynamic, dynamic>.from(entry.value as Map);

            return {
              'uid': entry.key.toString(),
              'name': (data['name'] ?? 'Unknown User').toString(),
              'xp': _toInt(data['xp']),
              'coins': _toInt(data['coins']),
              'streak': _toInt(data['streak']),
              'approvedChallenges': _toInt(data['approvedChallenges']),
              'approvedSubmissions': _toInt(data['approvedSubmissions']),
              'profilePic': (data['profilePic'] ?? '').toString(),
            };
          }).toList();

          users.sort((a, b) {
            final xpCompare = (b['xp'] as int).compareTo(a['xp'] as int);
            if (xpCompare != 0) return xpCompare;

            final coinsCompare =
                (b['coins'] as int).compareTo(a['coins'] as int);
            if (coinsCompare != 0) return coinsCompare;

            return (b['approvedChallenges'] as int)
                .compareTo(a['approvedChallenges'] as int);
          });

          if (users.isEmpty) {
            return const AppEmptyState(
              icon: Icons.emoji_events_outlined,
              title: 'No ranked users yet',
              subtitle:
                  'Your leaderboard is empty because nobody has earned meaningful progress yet.',
            );
          }

          final topThree = users.take(3).toList();
          final remaining = users.length > 3 ? users.sublist(3) : [];

          return RefreshIndicator(
            onRefresh: () async {},
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                const _LeaderboardHeader(),
                const SizedBox(height: 18),
                if (topThree.isNotEmpty) ...[
                  const Text(
                    'Top Performers',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(
                    topThree.length,
                    (index) => _TopRankCard(
                      rank: index + 1,
                      user: topThree[index],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                const Text(
                  'All Rankings',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (remaining.isEmpty)
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Only top-ranked users are available so far.'),
                    ),
                  )
                else
                  ...List.generate(
                    remaining.length,
                    (index) => _RankListTile(
                      rank: index + 4,
                      user: remaining[index],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value?.toString() ?? '0') ?? 0;
  }
}

class _LeaderboardHeader extends StatelessWidget {
  const _LeaderboardHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [
            Colors.green.shade400,
            Colors.teal.shade500,
          ],
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GrowTogether Champions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Ranked by XP, then coins, then approved challenges.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopRankCard extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> user;

  const _TopRankCard({
    required this.rank,
    required this.user,
  });

  Color _rankColor() {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.blueGrey;
      case 3:
        return Colors.deepOrange;
      default:
        return Colors.grey;
    }
  }

  String _rankTitle() {
    switch (rank) {
      case 1:
        return 'Champion';
      case 2:
        return 'Runner-up';
      case 3:
        return 'Third Place';
      default:
        return 'Ranked';
    }
  }

  IconData _rankIcon() {
    switch (rank) {
      case 1:
        return Icons.workspace_premium;
      case 2:
        return Icons.emoji_events;
      case 3:
        return Icons.military_tech;
      default:
        return Icons.star;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rankColor = _rankColor();
    final profilePic = (user['profilePic'] ?? '').toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: rankColor.withValues(alpha: 0.35),
            width: 1.3,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _ProfileAvatar(
                        name: user['name'],
                        profilePic: profilePic,
                        radius: 28,
                      ),
                      if (rank == 1)
                        const Positioned(
                          right: -4,
                          top: -6,
                          child: Icon(
                            Icons.workspace_premium,
                            color: Colors.amber,
                            size: 22,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user['name'] ?? 'Unknown User',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _rankTitle(),
                          style: TextStyle(
                            color: rankColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: rankColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        Icon(_rankIcon(), color: rankColor),
                        const SizedBox(height: 4),
                        Text(
                          '#$rank',
                          style: TextStyle(
                            color: rankColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _MetricBox(
                      label: 'XP',
                      value: '${user['xp']}',
                      icon: Icons.bolt,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricBox(
                      label: 'Coins',
                      value: '${user['coins']}',
                      icon: Icons.monetization_on,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _MetricBox(
                      label: 'Streak',
                      value: '${user['streak']}',
                      icon: Icons.local_fire_department,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricBox(
                      label: 'Approved',
                      value: '${user['approvedChallenges']}',
                      icon: Icons.check_circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: _LevelBadge(
                  xp: user['xp'] as int,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RankListTile extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> user;

  const _RankListTile({
    required this.rank,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final profilePic = (user['profilePic'] ?? '').toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 8,
        ),
        leading: CircleAvatar(
          backgroundColor: Colors.grey.shade200,
          child: Text(
            '$rank',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          user['name'] ?? 'Unknown User',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _MiniBadge(label: '${user['xp']} XP'),
              _MiniBadge(label: '${user['coins']} Coins'),
              _MiniBadge(label: '🔥 ${user['streak']}'),
              _MiniBadge(label: '✅ ${user['approvedChallenges']}'),
            ],
          ),
        ),
        trailing: _ProfileAvatar(
          name: user['name'],
          profilePic: profilePic,
          radius: 22,
        ),
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MetricBox({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12,
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

class _LevelBadge extends StatelessWidget {
  final int xp;

  const _LevelBadge({
    required this.xp,
  });

  String _levelText() {
    if (xp >= 1000) return 'Legend';
    if (xp >= 700) return 'Master';
    if (xp >= 400) return 'Pro';
    if (xp >= 200) return 'Rising Star';
    if (xp >= 75) return 'Active';
    return 'Beginner';
  }

  Color _levelColor() {
    if (xp >= 1000) return Colors.purple;
    if (xp >= 700) return Colors.indigo;
    if (xp >= 400) return Colors.teal;
    if (xp >= 200) return Colors.green;
    if (xp >= 75) return Colors.orange;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final color = _levelColor();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.28),
        ),
      ),
      child: Text(
        _levelText(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String label;

  const _MiniBadge({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12.5),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String name;
  final String profilePic;
  final double radius;

  const _ProfileAvatar({
    required this.name,
    required this.profilePic,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    if (profilePic.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(profilePic),
        onBackgroundImageError: (_, __) {},
      );
    }

    final firstLetter = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return CircleAvatar(
      radius: radius,
      child: Text(
        firstLetter,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}