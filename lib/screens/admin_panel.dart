import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../core/app_utils.dart';
import '../models/submission_model.dart';
import '../services/challenge_service.dart';
import '../widgets/state_widgets.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _pointsController = TextEditingController();

  final ChallengeService _challengeService = ChallengeService();

  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;

  bool _isCheckingAccess = true;
  bool _hasAdminAccess = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _verifyAdminAccess();
  }

  Future<void> _verifyAdminAccess() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;

      if (uid == null) {
        if (!mounted) return;
        setState(() {
          _hasAdminAccess = false;
          _isCheckingAccess = false;
        });
        return;
      }

      final isAdmin = await _challengeService.isAdmin(uid);

      if (!mounted) return;
      setState(() {
        _hasAdminAccess = isAdmin;
        _isCheckingAccess = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasAdminAccess = false;
        _isCheckingAccess = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );

    if (picked != null) {
      setState(() {
        _selectedStartDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
        );

        if (_selectedEndDate != null &&
            _selectedEndDate!.isBefore(_selectedStartDate!)) {
          _selectedEndDate = null;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final initial =
        _selectedEndDate ?? _selectedStartDate ?? now.add(const Duration(days: 7));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: _selectedStartDate ?? now,
      lastDate: DateTime(now.year + 5),
    );

    if (picked != null) {
      setState(() {
        _selectedEndDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
        );
      });
    }
  }

  Future<void> _addChallenge() async {
    final title = _titleController.text.trim();
    final description = _descController.text.trim();
    final points = int.tryParse(_pointsController.text.trim());

    if (title.isEmpty || points == null || points <= 0) {
      AppUtils.showSnack(
        context,
        'Title and valid point value are required',
        isError: true,
      );
      return;
    }

    if (_selectedStartDate == null || _selectedEndDate == null) {
      AppUtils.showSnack(
        context,
        'Please select both start and end dates',
        isError: true,
      );
      return;
    }

    if (_selectedEndDate!.isBefore(_selectedStartDate!)) {
      AppUtils.showSnack(
        context,
        'End date cannot be before start date',
        isError: true,
      );
      return;
    }

    try {
      await _challengeService.createChallenge(
        title: title,
        description: description,
        points: points,
        startDate: _selectedStartDate!,
        endDate: _selectedEndDate!,
      );

      _titleController.clear();
      _descController.clear();
      _pointsController.clear();

      setState(() {
        _selectedStartDate = null;
        _selectedEndDate = null;
      });

      if (!mounted) return;
      AppUtils.showSnack(context, 'Challenge created successfully');
    } catch (e) {
      if (!mounted) return;
      AppUtils.showSnack(
        context,
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  Future<void> _selectWinnerForChallenge({
    required String challengeId,
    required String challengeTitle,
    required String status,
  }) async {
    if (status == 'pending') {
      AppUtils.showSnack(
        context,
        'This challenge has not started yet.',
        isError: true,
      );
      return;
    }

    if (status == 'completed') {
      AppUtils.showSnack(
        context,
        'This challenge is already completed.',
        isError: true,
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    List<Map<String, dynamic>> approvedSubmissions = [];

    try {
      approvedSubmissions =
          await _challengeService.getApprovedSubmissionsForChallenge(challengeId);
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      if (!mounted) return;
      AppUtils.showSnack(
        context,
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
      return;
    }

    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    if (!mounted) return;

    if (approvedSubmissions.isEmpty) {
      AppUtils.showSnack(
        context,
        'No approved submissions found for this challenge.',
        isError: true,
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.75,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Winner',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  challengeTitle,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: ListView.builder(
                    itemCount: approvedSubmissions.length,
                    itemBuilder: (_, index) {
                      final submission = approvedSubmissions[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  child: Text('${index + 1}'),
                                ),
                                title: Text(
                                  submission['userName'] ?? 'Unknown',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  'Date: ${submission['submittedDate'] ?? '-'}',
                                ),
                                trailing: Text(
                                  '${submission['points'] ?? 0} coins',
                                ),
                              ),
                              if ((submission['imageUrl'] ?? '')
                                  .toString()
                                  .isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    submission['imageUrl'],
                                    height: 180,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      height: 180,
                                      alignment: Alignment.center,
                                      color: Colors.grey.shade200,
                                      child: const Text('Unable to load image'),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    Navigator.pop(context);

                                    try {
                                      await _challengeService.completeChallenge(
                                        challengeId: challengeId,
                                        winnerUserId: submission['userId'],
                                        winnerName: submission['userName'],
                                      );

                                      if (!mounted) return;
                                      AppUtils.showSnack(
                                        context,
                                        '${submission['userName']} selected as winner',
                                      );
                                    } catch (e) {
                                      if (!mounted) return;
                                      AppUtils.showSnack(
                                        context,
                                        e.toString().replaceFirst('Exception: ', ''),
                                        isError: true,
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.emoji_events),
                                  label: const Text('Select as Winner'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openAnalytics() {
    Navigator.pushNamed(context, '/admin-analytics');
  }

  void _openFraudMonitor() {
    Navigator.pushNamed(context, '/fraud-monitor');
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select date';
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'expired':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAccess) {
      return const Scaffold(
        body: AppLoadingState(
          title: 'Checking admin access...',
          subtitle: 'Verifying permissions before loading admin controls.',
        ),
      );
    }

    if (!_hasAdminAccess) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin Dashboard')),
        body: const AppErrorState(
          title: 'Access denied',
          message:
              'You are not an admin. If this screen was reachable, your navigation flow is weak.',
          onRetry: _noop,
          buttonText: 'Denied',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shield_outlined),
            tooltip: 'Fraud Monitor',
            onPressed: _openFraudMonitor,
          ),
          IconButton(
            icon: const Icon(Icons.query_stats),
            tooltip: 'Analytics',
            onPressed: _openAnalytics,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.add_task), text: 'Manage Challenges'),
            Tab(icon: Icon(Icons.rate_review), text: 'Review Proofs'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _manageChallengesTab(),
          _reviewTab(),
        ],
      ),
    );
  }

  Widget _manageChallengesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Add New Challenge',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Challenge Title',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _descController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _pointsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Coins Reward',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickStartDate,
                          icon: const Icon(Icons.calendar_today),
                          label: Text('Start: ${_formatDate(_selectedStartDate)}'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickEndDate,
                          icon: const Icon(Icons.event),
                          label: Text('End: ${_formatDate(_selectedEndDate)}'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _addChallenge,
                    child: const Text('Create Challenge'),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Divider(),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Current Challenges',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: StreamBuilder<DatabaseEvent>(
            stream: _challengeService.challengesStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                return const Center(child: Text('No challenges found.'));
              }

              final map = Map<dynamic, dynamic>.from(
                snapshot.data!.snapshot.value as Map,
              );
              final items = map.entries.toList();

              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (_, index) {
                  final challengeId = items[index].key.toString();
                  final challenge = Map<dynamic, dynamic>.from(
                    items[index].value as Map,
                  );

                  final status = challenge['status']?.toString() ?? 'unknown';
                  final startDate = challenge['startDate']?.toString() ?? '-';
                  final endDate = challenge['endDate']?.toString() ?? '-';
                  final winnerName = challenge['winnerName']?.toString();
                  final canSelectWinner =
                      status == 'expired' || status == 'active';

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      title: Text(challenge['title']?.toString() ?? ''),
                      subtitle: Text(
                        '${challenge['points']} coins\n'
                        'Status: $status\n'
                        'Start: $startDate\n'
                        'End: $endDate'
                        '${winnerName != null && winnerName.isNotEmpty ? '\nWinner: $winnerName' : ''}',
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (canSelectWinner)
                            IconButton(
                              tooltip: 'Select winner',
                              icon: Icon(
                                Icons.emoji_events,
                                color: _statusColor(status),
                              ),
                              onPressed: () => _selectWinnerForChallenge(
                                challengeId: challengeId,
                                challengeTitle: challenge['title']?.toString() ?? '',
                                status: status,
                              ),
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () async {
                              try {
                                await _challengeService.deleteChallenge(challengeId);
                                if (!mounted) return;
                                AppUtils.showSnack(context, 'Challenge deleted');
                              } catch (e) {
                                if (!mounted) return;
                                AppUtils.showSnack(
                                  context,
                                  e.toString().replaceFirst('Exception: ', ''),
                                  isError: true,
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _reviewTab() {
    return StreamBuilder<DatabaseEvent>(
      stream: _challengeService.pendingSubmissionsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return const Center(child: Text('No pending submissions.'));
        }

        final map = Map<dynamic, dynamic>.from(
          snapshot.data!.snapshot.value as Map,
        );

        final submissions = map.entries
            .map(
              (e) => SubmissionModel.fromMap(
                e.key.toString(),
                Map<dynamic, dynamic>.from(e.value as Map),
              ),
            )
            .toList();

        return ListView.builder(
          itemCount: submissions.length,
          itemBuilder: (_, index) {
            final submission = submissions[index];

            return Card(
              margin: const EdgeInsets.all(12),
              child: Column(
                children: [
                  ListTile(
                    tileColor: Colors.grey.shade100,
                    title: Text(
                      submission.userName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Challenge: ${submission.challengeTitle}\n'
                      'Date: ${submission.submittedDate}',
                    ),
                    trailing: Text('${submission.points} coins'),
                  ),
                  if (submission.imageUrl.isNotEmpty)
                    Image.network(
                      submission.imageUrl,
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Unable to load image'),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                await _challengeService.approveSubmission(
                                  submission.id,
                                  submission,
                                );
                                if (!mounted) return;
                                AppUtils.showSnack(context, 'Submission approved');
                              } catch (e) {
                                if (!mounted) return;
                                AppUtils.showSnack(
                                  context,
                                  e.toString().replaceFirst('Exception: ', ''),
                                  isError: true,
                                );
                              }
                            },
                            icon: const Icon(Icons.check),
                            label: const Text('Approve'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              try {
                                await _challengeService.rejectSubmission(
                                  submission.id,
                                  submission,
                                );
                                if (!mounted) return;
                                AppUtils.showSnack(context, 'Submission rejected');
                              } catch (e) {
                                if (!mounted) return;
                                AppUtils.showSnack(
                                  context,
                                  e.toString().replaceFirst('Exception: ', ''),
                                  isError: true,
                                );
                              }
                            },
                            icon: const Icon(Icons.close, color: Colors.red),
                            label: const Text(
                              'Reject',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static void _noop() {}
}