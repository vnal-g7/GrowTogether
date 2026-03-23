import 'package:firebase_database/firebase_database.dart';

class FraudDetectionService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  Future<List<Map<String, dynamic>>> getFraudAlerts() async {
    final submissionsSnap = await _db.child('submissions').get();

    if (!submissionsSnap.exists || submissionsSnap.value == null) {
      return [];
    }

    final rawSubs = Map<dynamic, dynamic>.from(submissionsSnap.value as Map);
    final submissions = rawSubs.entries.map((entry) {
      final map = Map<dynamic, dynamic>.from(entry.value as Map);
      return {
        'submissionId': entry.key.toString(),
        'userId': (map['userId'] ?? '').toString(),
        'challengeId': (map['challengeId'] ?? '').toString(),
        'imageUrl': (map['imageUrl'] ?? '').toString(),
        'status': (map['status'] ?? '').toString(),
        'submittedAt': (map['submittedAt'] ?? '').toString(),
        'submittedDate': (map['submittedDate'] ?? '').toString(),
      };
    }).toList();

    final List<Map<String, dynamic>> alerts = [];

    alerts.addAll(_detectRepeatedRejections(submissions));
    alerts.addAll(_detectDuplicateImageReuse(submissions));
    alerts.addAll(_detectRapidSubmissions(submissions));
    alerts.addAll(_detectTooManyDailySubmissions(submissions));

    alerts.sort((a, b) {
      final aSeverity = _severityScore(a['severity']?.toString() ?? 'low');
      final bSeverity = _severityScore(b['severity']?.toString() ?? 'low');
      return bSeverity.compareTo(aSeverity);
    });

    return alerts;
  }

  List<Map<String, dynamic>> _detectRepeatedRejections(
    List<Map<String, dynamic>> submissions,
  ) {
    final Map<String, int> rejectedCounts = {};

    for (final sub in submissions) {
      if (sub['status'] == 'rejected') {
        final userId = sub['userId']?.toString() ?? '';
        if (userId.isNotEmpty) {
          rejectedCounts[userId] = (rejectedCounts[userId] ?? 0) + 1;
        }
      }
    }

    final List<Map<String, dynamic>> alerts = [];

    rejectedCounts.forEach((userId, count) {
      if (count >= 3) {
        alerts.add({
          'type': 'Repeated Rejections',
          'severity': count >= 5 ? 'high' : 'medium',
          'userId': userId,
          'details': 'User has $count rejected submissions.',
        });
      }
    });

    return alerts;
  }

  List<Map<String, dynamic>> _detectDuplicateImageReuse(
    List<Map<String, dynamic>> submissions,
  ) {
    final Map<String, List<Map<String, dynamic>>> byImage = {};

    for (final sub in submissions) {
      final imageUrl = sub['imageUrl']?.toString() ?? '';
      if (imageUrl.isEmpty) continue;
      byImage.putIfAbsent(imageUrl, () => []).add(sub);
    }

    final List<Map<String, dynamic>> alerts = [];

    byImage.forEach((imageUrl, subs) {
      if (subs.length > 1) {
        final users = subs.map((e) => e['userId'].toString()).toSet().toList();
        alerts.add({
          'type': 'Duplicate Image Reuse',
          'severity': users.length > 1 ? 'high' : 'medium',
          'userId': users.join(', '),
          'details':
              'Same proof image appears in ${subs.length} submissions. Users: ${users.join(', ')}',
        });
      }
    });

    return alerts;
  }

  List<Map<String, dynamic>> _detectRapidSubmissions(
    List<Map<String, dynamic>> submissions,
  ) {
    final Map<String, List<Map<String, dynamic>>> byUser = {};

    for (final sub in submissions) {
      final userId = sub['userId']?.toString() ?? '';
      if (userId.isEmpty) continue;
      byUser.putIfAbsent(userId, () => []).add(sub);
    }

    final List<Map<String, dynamic>> alerts = [];

    for (final entry in byUser.entries) {
      final userId = entry.key;
      final subs = entry.value;

      subs.sort((a, b) {
        final aTime = DateTime.tryParse(a['submittedAt']?.toString() ?? '');
        final bTime = DateTime.tryParse(b['submittedAt']?.toString() ?? '');
        if (aTime == null || bTime == null) return 0;
        return aTime.compareTo(bTime);
      });

      for (int i = 1; i < subs.length; i++) {
        final prev = DateTime.tryParse(subs[i - 1]['submittedAt']?.toString() ?? '');
        final curr = DateTime.tryParse(subs[i]['submittedAt']?.toString() ?? '');

        if (prev == null || curr == null) continue;

        final diff = curr.difference(prev).inMinutes.abs();

        if (diff <= 2) {
          alerts.add({
            'type': 'Rapid Submissions',
            'severity': 'medium',
            'userId': userId,
            'details':
                'Two submissions were made within $diff minute(s). Check for suspicious activity.',
          });
          break;
        }
      }
    }

    return alerts;
  }

  List<Map<String, dynamic>> _detectTooManyDailySubmissions(
    List<Map<String, dynamic>> submissions,
  ) {
    final Map<String, int> counts = {};

    for (final sub in submissions) {
      final userId = sub['userId']?.toString() ?? '';
      final date = sub['submittedDate']?.toString() ?? '';
      if (userId.isEmpty || date.isEmpty) continue;

      final key = '$userId|$date';
      counts[key] = (counts[key] ?? 0) + 1;
    }

    final List<Map<String, dynamic>> alerts = [];

    counts.forEach((key, count) {
      if (count > 2) {
        final parts = key.split('|');
        final userId = parts.first;
        final date = parts.last;

        alerts.add({
          'type': 'Too Many Daily Submissions',
          'severity': count >= 4 ? 'high' : 'medium',
          'userId': userId,
          'details': '$count submissions were made on $date.',
        });
      }
    });

    return alerts;
  }

  int _severityScore(String severity) {
    switch (severity) {
      case 'high':
        return 3;
      case 'medium':
        return 2;
      default:
        return 1;
    }
  }
}