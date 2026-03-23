import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/app_utils.dart';
import '../models/challenge_model.dart';
import '../services/challenge_service.dart';
import '../services/upload_service.dart';
import '../widgets/challenge_widgets.dart';
import '../widgets/notification_center_sheet.dart';
import '../widgets/state_widgets.dart';
import 'admin_panel.dart';
import 'camera_screen.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  final ChallengeService _challengeService = ChallengeService();
  final UploadService _uploadService = UploadService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isAdmin = false;
  bool _isRefreshingStatuses = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadAdminStatus();
    await _refreshChallengeStatuses();
  }

  Future<void> _loadAdminStatus() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final isAdmin = await _challengeService.isAdmin(uid);
    if (!mounted) return;

    setState(() {
      _isAdmin = isAdmin;
    });
  }

  Future<void> _refreshChallengeStatuses() async {
    if (_isRefreshingStatuses) return;

    setState(() {
      _isRefreshingStatuses = true;
    });

    try {
      await _challengeService.refreshChallengeStatuses();
    } catch (_) {
      // Keep silent here. UI failure is better than screen crash.
    } finally {
      if (!mounted) return;
      setState(() {
        _isRefreshingStatuses = false;
      });
    }
  }

  Future<void> _startLiveVerification(ChallengeModel challenge) async {
    if (challenge.status != 'active') {
      AppUtils.showSnack(
        context,
        'This challenge is not active right now.',
        isError: true,
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CameraScreen()),
    );

    if (result == null || !mounted) return;

    _showPreviewDialog(XFile(result.toString()), challenge);
  }

  void _showPreviewDialog(XFile file, ChallengeModel challenge) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Submission'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This proof will be sent to admin review. Gallery uploads are disabled.',
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 200,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: kIsWeb
                    ? Image.network(file.path, fit: BoxFit.cover)
                    : Image.file(File(file.path), fit: BoxFit.cover),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processUpload(file, challenge);
            },
            child: const Text('Submit Proof'),
          ),
        ],
      ),
    );
  }

  Future<void> _processUpload(XFile file, ChallengeModel challenge) async {
    final user = _auth.currentUser;
    if (user == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final String downloadUrl = await _uploadService.uploadChallengeImage(
        file: file,
        userId: user.uid,
        challengeId: challenge.id,
      );

      await _challengeService.submitProof(
        challengeId: challenge.id,
        challengeTitle: challenge.title,
        points: challenge.points,
        imageUrl: downloadUrl,
      );

      if (!mounted) return;

      AppUtils.showSnack(
        context,
        'Proof submitted successfully. Waiting for admin review.',
      );
    } catch (e) {
      if (!mounted) return;

      AppUtils.showSnack(
        context,
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  Future<void> _showNotifications() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => NotificationCenterSheet(
        uid: uid,
        challengeService: _challengeService,
      ),
    );
  }

  List<ChallengeModel> _sortChallenges(List<ChallengeModel> items) {
    items.sort((a, b) {
      final statusOrder = {
        'active': 0,
        'pending': 1,
        'expired': 2,
        'completed': 3,
      };

      final aOrder = statusOrder[a.status] ?? 99;
      final bOrder = statusOrder[b.status] ?? 99;

      if (aOrder != bOrder) {
        return aOrder.compareTo(bOrder);
      }

      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });

    return items;
  }

  List<ChallengeModel> _filterByStatus(
    List<ChallengeModel> items,
    String status,
  ) {
    return items.where((challenge) => challenge.status == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Challenges'),
        actions: [
          if (_isRefreshingStatuses)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          IconButton(
            onPressed: _refreshChallengeStatuses,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh challenge statuses',
          ),
          if (uid != null)
            StreamBuilder<DatabaseEvent>(
              stream: _challengeService.unreadNotificationsStream(uid),
              builder: (context, snapshot) {
                int unreadCount = 0;

                if (snapshot.hasData && snapshot.data?.snapshot.value != null) {
                  final raw = snapshot.data!.snapshot.value;
                  if (raw is Map) {
                    unreadCount = raw.length;
                  }
                }

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      onPressed: _showNotifications,
                      icon: const Icon(Icons.notifications_none),
                      tooltip: 'Notifications',
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          if (_isAdmin)
            IconButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminPanel()),
              ),
              icon: const Icon(Icons.admin_panel_settings_outlined),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshChallengeStatuses,
        child: StreamBuilder<DatabaseEvent>(
          stream: _challengeService.challengesStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AppLoadingState(
                title: 'Loading challenges...',
                subtitle: 'Fetching challenge schedule and status information.',
              );
            }

            if (snapshot.hasError) {
              return AppErrorState(
                message:
                    'Challenges failed to load. That means the core user flow is broken until this is fixed.',
                onRetry: _refreshChallengeStatuses,
              );
            }

            if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
              return AppEmptyState(
                icon: Icons.assignment_outlined,
                title: 'No challenges available',
                subtitle:
                    'Admins have not published any challenges yet. This screen should never feel dead, so at least now it explains itself.',
                buttonText: 'Refresh',
                onPressed: _refreshChallengeStatuses,
              );
            }

            final rawValue = snapshot.data!.snapshot.value;
            if (rawValue is! Map) {
              return AppEmptyState(
                icon: Icons.assignment_outlined,
                title: 'Invalid challenge data',
                subtitle:
                    'Challenge data exists, but the structure is broken.',
                buttonText: 'Refresh',
                onPressed: _refreshChallengeStatuses,
              );
            }

            final map = Map<dynamic, dynamic>.from(rawValue);

            final challenges = _sortChallenges(
              map.entries
                  .map(
                    (e) => ChallengeModel.fromMap(
                      e.key.toString(),
                      Map<dynamic, dynamic>.from(e.value as Map),
                    ),
                  )
                  .toList(),
            );

            if (challenges.isEmpty) {
              return AppEmptyState(
                icon: Icons.assignment_outlined,
                title: 'No challenges available',
                subtitle:
                    'There is challenge data storage, but nothing useful in it yet.',
                buttonText: 'Refresh',
                onPressed: _refreshChallengeStatuses,
              );
            }

            final activeChallenges = _filterByStatus(challenges, 'active');
            final pendingChallenges = _filterByStatus(challenges, 'pending');
            final expiredChallenges = _filterByStatus(challenges, 'expired');
            final completedChallenges = _filterByStatus(
              challenges,
              'completed',
            );

            return ListView(
              padding: const EdgeInsets.only(bottom: 18),
              children: [
                const SizedBox(height: 8),
                ChallengeSection(
                  title: 'Active Challenges',
                  icon: Icons.local_fire_department,
                  challenges: activeChallenges,
                  emptyText: 'No active challenges right now.',
                  onTapChallenge: _startLiveVerification,
                ),
                ChallengeSection(
                  title: 'Upcoming Challenges',
                  icon: Icons.schedule,
                  challenges: pendingChallenges,
                  emptyText: 'No upcoming challenges.',
                  onTapChallenge: _startLiveVerification,
                ),
                ChallengeSection(
                  title: 'Expired Challenges',
                  icon: Icons.hourglass_disabled,
                  challenges: expiredChallenges,
                  emptyText: 'No expired challenges.',
                  onTapChallenge: _startLiveVerification,
                ),
                ChallengeSection(
                  title: 'Completed Challenges',
                  icon: Icons.emoji_events,
                  challenges: completedChallenges,
                  emptyText: 'No completed challenges yet.',
                  onTapChallenge: _startLiveVerification,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}