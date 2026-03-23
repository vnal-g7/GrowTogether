import 'package:flutter/material.dart';

class ChallengeUiUtils {
  static String submissionBlockedMessage(String status) {
    switch (status) {
      case 'pending':
        return 'This challenge has not started yet.';
      case 'expired':
        return 'This challenge has already expired.';
      case 'completed':
        return 'This challenge has already been completed.';
      default:
        return 'This challenge is not available right now.';
    }
  }

  static Color statusColor(String status) {
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

  static String statusLabel(String status) {
    switch (status) {
      case 'active':
        return 'Active';
      case 'pending':
        return 'Pending';
      case 'expired':
        return 'Expired';
      case 'completed':
        return 'Completed';
      default:
        return 'Unknown';
    }
  }

  static String formatTimestamp(int timestamp) {
    if (timestamp <= 0) return 'Unknown time';

    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';

    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}