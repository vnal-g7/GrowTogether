import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../core/app_utils.dart';
import '../models/notification_model.dart';
import '../services/challenge_service.dart';
import '../utils/challenge_ui_utils.dart';
import 'state_widgets.dart';

class NotificationCenterSheet extends StatelessWidget {
  final String uid;
  final ChallengeService challengeService;

  const NotificationCenterSheet({
    super.key,
    required this.uid,
    required this.challengeService,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.72,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      await challengeService.markAllNotificationsAsRead(uid);
                      if (context.mounted) {
                        AppUtils.showSnack(
                          context,
                          'All notifications marked as read',
                        );
                      }
                    },
                    icon: const Icon(Icons.done_all),
                    label: const Text('Mark all read'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: StreamBuilder<DatabaseEvent>(
                  stream: challengeService.notificationsStream(uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const AppLoadingState(
                        title: 'Loading notifications...',
                        topSpacing: 70,
                      );
                    }

                    if (snapshot.hasError) {
                      return AppErrorState(
                        topSpacing: 70,
                        message:
                            'Notifications failed to load. That is bad UX, so try again.',
                        onRetry: () {},
                      );
                    }

                    if (!snapshot.hasData ||
                        snapshot.data!.snapshot.value == null) {
                      return const AppEmptyState(
                        icon: Icons.notifications_off_outlined,
                        title: 'No notifications yet',
                        subtitle:
                            'When submissions are approved, rejected, or you win a challenge, updates will appear here.',
                        topSpacing: 70,
                      );
                    }

                    final map = Map<dynamic, dynamic>.from(
                      snapshot.data!.snapshot.value as Map,
                    );

                    final notifications = map.entries
                        .map(
                          (e) => NotificationModel.fromMap(
                            e.key.toString(),
                            Map<dynamic, dynamic>.from(e.value as Map),
                          ),
                        )
                        .toList()
                      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

                    if (notifications.isEmpty) {
                      return const AppEmptyState(
                        icon: Icons.notifications_off_outlined,
                        title: 'No notifications yet',
                        subtitle:
                            'When submissions are approved, rejected, or you win a challenge, updates will appear here.',
                        topSpacing: 70,
                      );
                    }

                    return ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, index) {
                        final notification = notifications[index];
                        return NotificationTile(
                          notification: notification,
                          timeLabel: ChallengeUiUtils.formatTimestamp(
                            notification.timestamp,
                          ),
                          onTap: () async {
                            if (!notification.isRead) {
                              await challengeService.markNotificationAsRead(
                                uid: uid,
                                notificationId: notification.id,
                              );
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final String timeLabel;
  final VoidCallback onTap;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.timeLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = notification.isRead
        ? Colors.white
        : Theme.of(context).colorScheme.primary.withValues(alpha: 0.08);

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: notification.isRead
                  ? Colors.grey.shade300
                  : Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.12),
                    child: Icon(
                      Icons.notifications_active_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  if (!notification.isRead)
                    Positioned(
                      right: -1,
                      top: -1,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: notification.isRead
                            ? FontWeight.w600
                            : FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.body,
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      timeLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}