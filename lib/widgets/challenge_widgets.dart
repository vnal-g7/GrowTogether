import 'package:flutter/material.dart';

import '../models/challenge_model.dart';
import '../utils/challenge_ui_utils.dart';

class ChallengeInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const ChallengeInfoChip({
    super.key,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.grey.shade700),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}

class ChallengeSectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;

  const ChallengeSectionHeader({
    super.key,
    required this.title,
    required this.count,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 10),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Text(
            '$title ($count)',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class ChallengeCard extends StatelessWidget {
  final ChallengeModel challenge;
  final VoidCallback? onSubmit;

  const ChallengeCard({
    super.key,
    required this.challenge,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = ChallengeUiUtils.statusColor(challenge.status);
    final canSubmit = challenge.status == 'active';

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    challenge.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${challenge.points} Coins'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              challenge.description.isEmpty
                  ? 'No description added.'
                  : challenge.description,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    ChallengeUiUtils.statusLabel(challenge.status),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ChallengeInfoChip(
                  icon: Icons.play_arrow,
                  label: 'Start: ${challenge.startDate}',
                ),
                ChallengeInfoChip(
                  icon: Icons.event,
                  label: 'End: ${challenge.endDate}',
                ),
                if (challenge.status == 'completed' &&
                    challenge.winnerName != null &&
                    challenge.winnerName!.isNotEmpty)
                  ChallengeInfoChip(
                    icon: Icons.emoji_events,
                    label: 'Winner: ${challenge.winnerName}',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Icon(Icons.verified, size: 18, color: Colors.green),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Requires live camera capture. No gallery, no fake uploads.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: canSubmit ? onSubmit : null,
                icon: Icon(
                  canSubmit ? Icons.camera_alt_outlined : Icons.lock_outline,
                ),
                label: Text(
                  canSubmit
                      ? 'Verify with Live Camera'
                      : ChallengeUiUtils.statusLabel(challenge.status),
                ),
              ),
            ),
            if (!canSubmit) ...[
              const SizedBox(height: 8),
              Text(
                challenge.status == 'completed' &&
                        challenge.winnerName != null &&
                        challenge.winnerName!.isNotEmpty
                    ? 'This challenge has been completed. Winner: ${challenge.winnerName}'
                    : ChallengeUiUtils.submissionBlockedMessage(
                        challenge.status,
                      ),
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ChallengeSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<ChallengeModel> challenges;
  final String emptyText;
  final ValueChanged<ChallengeModel> onTapChallenge;

  const ChallengeSection({
    super.key,
    required this.title,
    required this.icon,
    required this.challenges,
    required this.emptyText,
    required this.onTapChallenge,
  });

  @override
  Widget build(BuildContext context) {
    if (challenges.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(emptyText),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChallengeSectionHeader(
          title: title,
          count: challenges.length,
          icon: icon,
        ),
        ...challenges.map(
          (challenge) => ChallengeCard(
            challenge: challenge,
            onSubmit: () => onTapChallenge(challenge),
          ),
        ),
      ],
    );
  }
}