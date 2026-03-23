import 'package:flutter/material.dart';

import '../services/fraud_ditection_service.dart';

class FraudMonitorScreen extends StatefulWidget {
  const FraudMonitorScreen({super.key});

  @override
  State<FraudMonitorScreen> createState() => _FraudMonitorScreenState();
}

class _FraudMonitorScreenState extends State<FraudMonitorScreen> {
  final FraudDetectionService _fraudDetectionService = FraudDetectionService();
  late Future<List<Map<String, dynamic>>> _alertsFuture;

  @override
  void initState() {
    super.initState();
    _alertsFuture = _fraudDetectionService.getFraudAlerts();
  }

  Future<void> _refresh() async {
    setState(() {
      _alertsFuture = _fraudDetectionService.getFraudAlerts();
    });
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fraud Monitor'),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _alertsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final alerts = snapshot.data ?? [];
          final highCount =
              alerts.where((e) => (e['severity'] ?? '') == 'high').length;
          final mediumCount =
              alerts.where((e) => (e['severity'] ?? '') == 'medium').length;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _summaryCard(
                      'Total Alerts',
                      '${alerts.length}',
                      Icons.warning_amber_rounded,
                    ),
                    _summaryCard(
                      'High Risk',
                      '$highCount',
                      Icons.dangerous,
                    ),
                    _summaryCard(
                      'Medium Risk',
                      '$mediumCount',
                      Icons.report_problem,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Suspicious Activity Alerts',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (alerts.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No suspicious activity detected.'),
                    ),
                  )
                else
                  ...alerts.map((alert) {
                    final severity = (alert['severity'] ?? 'low').toString();
                    final color = _severityColor(severity);

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withOpacity(0.12),
                          child: Icon(Icons.shield_outlined, color: color),
                        ),
                        title: Text(
                          alert['type']?.toString() ?? 'Unknown Alert',
                        ),
                        subtitle: Text(
                          'User: ${alert['userId']}\n${alert['details']}',
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            severity.toUpperCase(),
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        isThreeLine: true,
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _summaryCard(String title, String value, IconData icon) {
    return SizedBox(
      width: 180,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon),
              const SizedBox(height: 10),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(title),
            ],
          ),
        ),
      ),
    );
  }
}