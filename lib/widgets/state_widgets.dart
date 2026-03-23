import 'package:flutter/material.dart';

class AppLoadingState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double topSpacing;

  const AppLoadingState({
    super.key,
    this.title = 'Loading...',
    this.subtitle,
    this.topSpacing = 120,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: topSpacing),
        const Center(
          child: SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? buttonText;
  final VoidCallback? onPressed;
  final double topSpacing;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.buttonText,
    this.onPressed,
    this.topSpacing = 110,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: topSpacing),
        Center(
          child: CircleAvatar(
            radius: 34,
            backgroundColor: Colors.grey.shade100,
            child: Icon(
              icon,
              size: 34,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade700,
              height: 1.35,
            ),
          ),
        ),
        if (buttonText != null && onPressed != null) ...[
          const SizedBox(height: 18),
          Center(
            child: ElevatedButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.refresh),
              label: Text(buttonText!),
            ),
          ),
        ],
      ],
    );
  }
}

class AppErrorState extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback onRetry;
  final double topSpacing;

  const AppErrorState({
    super.key,
    this.title = 'Something went wrong',
    required this.message,
    this.buttonText = 'Try Again',
    required this.onRetry,
    this.topSpacing = 110,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: topSpacing),
        Center(
          child: CircleAvatar(
            radius: 34,
            backgroundColor: Colors.red.shade50,
            child: Icon(
              Icons.error_outline,
              size: 34,
              color: Colors.red.shade400,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade700,
              height: 1.35,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(buttonText),
          ),
        ),
      ],
    );
  }
}