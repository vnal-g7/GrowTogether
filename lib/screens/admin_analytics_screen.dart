import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../services/analytics_service.dart';
import '../widgets/state_widgets.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();

  AnalyticsSummary? summary;
  ModerationBreakdown? moderation;
  List<SubmissionTrendPoint> trend = [];
  List<XpBucket> xpDistribution = [];

  bool isLoading = true;
  int selectedDays = 7;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadAnalytics();
  }

  Future<void> loadAnalytics() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final loadedSummary = await _analyticsService.getAnalyticsSummary();
      final loadedModeration =
          await _analyticsService.getModerationBreakdown();
      final loadedTrend =
          await _analyticsService.getSubmissionTrend(days: selectedDays);
      final loadedXp = await _analyticsService.getXpDistribution();

      setState(() {
        summary = loadedSummary;
        moderation = loadedModeration;
        trend = loadedTrend;
        xpDistribution = loadedXp;
        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  bool get _hasAnyData {
    if (summary == null || moderation == null) return false;

    return summary!.totalUsers > 0 ||
        summary!.pending > 0 ||
        summary!.approved > 0 ||
        summary!.rejected > 0 ||
        summary!.topUsers.isNotEmpty ||
        trend.isNotEmpty ||
        xpDistribution.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Analytics'),
        actions: [
          IconButton(
            onPressed: loadAnalytics,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (isLoading) {
            return const AppLoadingState(
              title: 'Loading analytics...',
              subtitle: 'Crunching user stats, moderation metrics, and charts.',
            );
          }

          if (errorMessage != null) {
            return AppErrorState(
              message: errorMessage!,
              onRetry: loadAnalytics,
            );
          }

          if (!_hasAnyData) {
            return AppEmptyState(
              icon: Icons.query_stats,
              title: 'No analytics data yet',
              subtitle:
                  'Once users join and submissions start coming in, your charts and admin insights will appear here.',
              buttonText: 'Refresh',
              onPressed: loadAnalytics,
            );
          }

          return RefreshIndicator(
            onRefresh: loadAnalytics,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overview',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildStatCard(
                        title: 'Total Users',
                        value: summary!.totalUsers.toString(),
                        icon: Icons.people,
                        color: Colors.blue,
                      ),
                      _buildStatCard(
                        title: 'Pending',
                        value: summary!.pending.toString(),
                        icon: Icons.hourglass_top,
                        color: Colors.orange,
                      ),
                      _buildStatCard(
                        title: 'Approved',
                        value: summary!.approved.toString(),
                        icon: Icons.check_circle,
                        color: Colors.green,
                      ),
                      _buildStatCard(
                        title: 'Rejected',
                        value: summary!.rejected.toString(),
                        icon: Icons.cancel,
                        color: Colors.red,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            colorScheme.primary.withValues(alpha: 0.12),
                        child: Icon(
                          Icons.percent,
                          color: colorScheme.primary,
                        ),
                      ),
                      title: const Text('Approval Rate'),
                      subtitle: const Text(
                        'Calculated from reviewed submissions only',
                      ),
                      trailing: Text(
                        '${summary!.approvalRate.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Moderation Breakdown'),
                  const SizedBox(height: 12),
                  _buildChartCard(
                    child: SizedBox(
                      height: 260,
                      child: moderation!.pending == 0 &&
                              moderation!.approved == 0 &&
                              moderation!.rejected == 0
                          ? const Center(
                              child: Text('No moderation data yet.'),
                            )
                          : Column(
                              children: [
                                Expanded(
                                  child: PieChart(
                                    PieChartData(
                                      sectionsSpace: 3,
                                      centerSpaceRadius: 42,
                                      sections: [
                                        PieChartSectionData(
                                          value:
                                              moderation!.pending.toDouble(),
                                          title: '${moderation!.pending}',
                                          radius: 58,
                                          color: Colors.orange,
                                          titleStyle: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        PieChartSectionData(
                                          value:
                                              moderation!.approved.toDouble(),
                                          title: '${moderation!.approved}',
                                          radius: 58,
                                          color: Colors.green,
                                          titleStyle: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        PieChartSectionData(
                                          value:
                                              moderation!.rejected.toDouble(),
                                          title: '${moderation!.rejected}',
                                          radius: 58,
                                          color: Colors.red,
                                          titleStyle: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Wrap(
                                  spacing: 16,
                                  runSpacing: 8,
                                  children: [
                                    _LegendItem(
                                      color: Colors.orange,
                                      label: 'Pending',
                                    ),
                                    _LegendItem(
                                      color: Colors.green,
                                      label: 'Approved',
                                    ),
                                    _LegendItem(
                                      color: Colors.red,
                                      label: 'Rejected',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle('Submissions Over Time'),
                      Wrap(
                        spacing: 8,
                        children: [7, 14, 30].map((days) {
                          final selected = selectedDays == days;
                          return ChoiceChip(
                            label: Text('${days}D'),
                            selected: selected,
                            onSelected: (_) async {
                              setState(() {
                                selectedDays = days;
                              });
                              await loadAnalytics();
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildChartCard(
                    child: SizedBox(
                      height: 280,
                      child: trend.isEmpty
                          ? const Center(
                              child: Text('No trend data available.'),
                            )
                          : LineChart(
                              LineChartData(
                                minY: 0,
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                ),
                                borderData: FlBorderData(show: false),
                                titlesData: FlTitlesData(
                                  rightTitles: AxisTitles(
                                    sideTitles:
                                        SideTitles(showTitles: false),
                                  ),
                                  topTitles: AxisTitles(
                                    sideTitles:
                                        SideTitles(showTitles: false),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 32,
                                      interval: 1,
                                    ),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 40,
                                      getTitlesWidget: (value, meta) {
                                        final index = value.toInt();
                                        if (index < 0 ||
                                            index >= trend.length) {
                                          return const SizedBox();
                                        }

                                        final step =
                                            trend.length > 14 ? 3 : 1;
                                        if (index % step != 0 &&
                                            index != trend.length - 1) {
                                          return const SizedBox();
                                        }

                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8,
                                          ),
                                          child: Text(
                                            trend[index].label,
                                            style: const TextStyle(
                                              fontSize: 10,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                lineBarsData: [
                                  LineChartBarData(
                                    isCurved: true,
                                    barWidth: 4,
                                    dotData: FlDotData(show: true),
                                    belowBarData: BarAreaData(show: true),
                                    spots: List.generate(
                                      trend.length,
                                      (index) => FlSpot(
                                        index.toDouble(),
                                        trend[index].count.toDouble(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle('XP Distribution'),
                  const SizedBox(height: 12),
                  _buildChartCard(
                    child: SizedBox(
                      height: 300,
                      child: xpDistribution.isEmpty
                          ? const Center(
                              child: Text('No XP data available.'),
                            )
                          : BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: _calculateMaxXpY(),
                                gridData: FlGridData(show: true),
                                borderData: FlBorderData(show: false),
                                titlesData: FlTitlesData(
                                  rightTitles: AxisTitles(
                                    sideTitles:
                                        SideTitles(showTitles: false),
                                  ),
                                  topTitles: AxisTitles(
                                    sideTitles:
                                        SideTitles(showTitles: false),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 32,
                                      interval: 1,
                                    ),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        final index = value.toInt();
                                        if (index < 0 ||
                                            index >=
                                                xpDistribution.length) {
                                          return const SizedBox();
                                        }

                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8,
                                          ),
                                          child: Text(
                                            xpDistribution[index].label,
                                            style: const TextStyle(
                                              fontSize: 10,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                barGroups: List.generate(
                                  xpDistribution.length,
                                  (index) => BarChartGroupData(
                                    x: index,
                                    barRods: [
                                      BarChartRodData(
                                        toY: xpDistribution[index]
                                            .count
                                            .toDouble(),
                                        width: 22,
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Top 5 Users by XP'),
                  const SizedBox(height: 12),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: summary!.topUsers.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('No user data available.'),
                          )
                        : Column(
                            children: List.generate(
                              summary!.topUsers.length,
                              (index) {
                                final user = summary!.topUsers[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    child: Text('${index + 1}'),
                                  ),
                                  title: Text(
                                    user['name'] ?? 'Unknown',
                                  ),
                                  subtitle: Text(
                                    'User ID: ${user['userId']}',
                                  ),
                                  trailing: Text(
                                    '${user['xp']} XP',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard({required Widget child}) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  double _calculateMaxXpY() {
    if (xpDistribution.isEmpty) return 5;
    final maxValue =
        xpDistribution.map((e) => e.count).reduce((a, b) => a > b ? a : b);
    return (maxValue + 1).toDouble();
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}