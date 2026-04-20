import 'package:flutter/material.dart';

enum VerificationStatusModalType { success, pending, failed }

class VerificationStatusModal extends StatelessWidget {
  final VerificationStatusModalType type;
  final String title;
  final String message;
  final String ctaLabel;
  final VoidCallback? onCtaPressed;

  const VerificationStatusModal({
    super.key,
    required this.type,
    required this.title,
    required this.message,
    required this.ctaLabel,
    this.onCtaPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bool isSuccess = type == VerificationStatusModalType.success;
    final bool isPending = type == VerificationStatusModalType.pending;
    final Color accent = isSuccess
        ? Colors.green
        : isPending
            ? Colors.orange
            : Colors.red;
    final IconData icon = isSuccess
        ? Icons.check_circle
        : isPending
            ? Icons.hourglass_top_rounded
            : Icons.error;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: accent,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onCtaPressed ?? () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(ctaLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
