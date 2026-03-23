import 'package:firebase_database/firebase_database.dart';

import '../utils/firebase_value_utils.dart';

class AnalyticsSummary {
  final int totalUsers;
  final int pending;
  final int approved;
  final int rejected;
  final double approvalRate;
  final List<Map<String, dynamic>> topUsers;

  AnalyticsSummary({
    required this.totalUsers,
    required this.pending,
    required this.approved,
    required this.rejected,
    required this.approvalRate,
    required this.topUsers,
  });
}

class ModerationBreakdown {
  final int pending;
  final int approved;
  final int rejected;

  ModerationBreakdown({
    required this.pending,
    required this.approved,
    required this.rejected,
  });
}

class SubmissionTrendPoint {
  final String label;
  final int count;

  SubmissionTrendPoint({
    required this.label,
    required this.count,
  });
}

class XpBucket {
  final String label;
  final int count;

  XpBucket({
    required this.label,
    required this.count,
  });
}

class AnalyticsService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  Future<AnalyticsSummary> getAnalyticsSummary() async {
    final usersSnapshot = await _db.ref('users').get();
    final submissionsSnapshot = await _db.ref('submissions').get();

    int totalUsers = 0;
    int pending = 0;
    int approved = 0;
    int rejected = 0;

    List<Map<String, dynamic>> topUsers = [];

    if (usersSnapshot.exists) {
      final usersData = FirebaseValueUtils.asMap(usersSnapshot.value);
      totalUsers = usersData.length;

      topUsers = usersData.entries.map((entry) {
        final userData = FirebaseValueUtils.asMap(entry.value);
        return {
          'userId': entry.key.toString(),
          'name': FirebaseValueUtils.asString(
            userData['name'],
            fallback: 'Unknown',
          ),
          'xp': FirebaseValueUtils.asInt(userData['xp']),
        };
      }).toList();

      topUsers.sort((a, b) => (b['xp'] as int).compareTo(a['xp'] as int));
      topUsers = topUsers.take(5).toList();
    }

    if (submissionsSnapshot.exists) {
      final submissionsData = FirebaseValueUtils.asMap(submissionsSnapshot.value);

      for (final entry in submissionsData.entries) {
        final submission = FirebaseValueUtils.asMap(entry.value);
        final status = FirebaseValueUtils.asString(
          submission['status'],
          fallback: 'pending',
        );

        if (status == 'pending') pending++;
        if (status == 'approved') approved++;
        if (status == 'rejected') rejected++;
      }
    }

    final reviewed = approved + rejected;
    final approvalRate = reviewed > 0 ? (approved / reviewed) * 100 : 0.0;

    return AnalyticsSummary(
      totalUsers: totalUsers,
      pending: pending,
      approved: approved,
      rejected: rejected,
      approvalRate: approvalRate,
      topUsers: topUsers,
    );
  }

  Future<ModerationBreakdown> getModerationBreakdown() async {
    final submissionsSnapshot = await _db.ref('submissions').get();

    int pending = 0;
    int approved = 0;
    int rejected = 0;

    if (submissionsSnapshot.exists) {
      final submissionsData = FirebaseValueUtils.asMap(submissionsSnapshot.value);

      for (final entry in submissionsData.entries) {
        final submission = FirebaseValueUtils.asMap(entry.value);
        final status = FirebaseValueUtils.asString(
          submission['status'],
          fallback: 'pending',
        );

        if (status == 'pending') pending++;
        if (status == 'approved') approved++;
        if (status == 'rejected') rejected++;
      }
    }

    return ModerationBreakdown(
      pending: pending,
      approved: approved,
      rejected: rejected,
    );
  }

  Future<List<SubmissionTrendPoint>> getSubmissionTrend({int days = 7}) async {
    final submissionsSnapshot = await _db.ref('submissions').get();

    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days - 1));

    final Map<String, int> dailyCounts = {};

    for (int i = 0; i < days; i++) {
      final date = startDate.add(Duration(days: i));
      final key = _formatDateKey(date);
      dailyCounts[key] = 0;
    }

    if (submissionsSnapshot.exists) {
      final submissionsData = FirebaseValueUtils.asMap(submissionsSnapshot.value);

      for (final entry in submissionsData.entries) {
        final submission = FirebaseValueUtils.asMap(entry.value);

        DateTime? submittedDate;

        final submittedAt = submission['submittedAt'];
        if (submittedAt != null) {
          final parsedMillis =
              FirebaseValueUtils.asDateTimeFromMilliseconds(submittedAt);
          if (parsedMillis != null) {
            submittedDate = parsedMillis;
          } else if (submittedAt is String) {
            submittedDate = DateTime.tryParse(submittedAt);
          }
        }

        if (submittedDate == null && submission['submittedDate'] != null) {
          final submittedDateString =
              FirebaseValueUtils.asString(submission['submittedDate']);
          submittedDate = DateTime.tryParse(submittedDateString);
        }

        if (submittedDate != null) {
          final key = _formatDateKey(submittedDate);
          if (dailyCounts.containsKey(key)) {
            dailyCounts[key] = dailyCounts[key]! + 1;
          }
        }
      }
    }

    final List<SubmissionTrendPoint> trend = [];
    for (int i = 0; i < days; i++) {
      final date = startDate.add(Duration(days: i));
      final key = _formatDateKey(date);

      trend.add(
        SubmissionTrendPoint(
          label: _formatShortLabel(date),
          count: dailyCounts[key] ?? 0,
        ),
      );
    }

    return trend;
  }

  Future<List<XpBucket>> getXpDistribution() async {
    final usersSnapshot = await _db.ref('users').get();

    final Map<String, int> buckets = {
      '0-50': 0,
      '51-100': 0,
      '101-200': 0,
      '201-500': 0,
      '500+': 0,
    };

    if (usersSnapshot.exists) {
      final usersData = FirebaseValueUtils.asMap(usersSnapshot.value);

      for (final entry in usersData.entries) {
        final userData = FirebaseValueUtils.asMap(entry.value);
        final xp = FirebaseValueUtils.asInt(userData['xp']);

        if (xp <= 50) {
          buckets['0-50'] = buckets['0-50']! + 1;
        } else if (xp <= 100) {
          buckets['51-100'] = buckets['51-100']! + 1;
        } else if (xp <= 200) {
          buckets['101-200'] = buckets['101-200']! + 1;
        } else if (xp <= 500) {
          buckets['201-500'] = buckets['201-500']! + 1;
        } else {
          buckets['500+'] = buckets['500+']! + 1;
        }
      }
    }

    return buckets.entries
        .map((e) => XpBucket(label: e.key, count: e.value))
        .toList();
  }

  String _formatDateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _formatShortLabel(DateTime date) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${months[date.month]}';
  }
}