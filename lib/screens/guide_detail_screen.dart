import 'package:flutter/material.dart';

import 'resources_insights_screen.dart' show GuideItem;

class GuideDetailScreen extends StatelessWidget {
  final GuideItem guide;

  const GuideDetailScreen({super.key, required this.guide});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guide'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          children: [
            Row(
              children: [
                if (guide.categoryId.isNotEmpty) ...[
                  _Pill(
                    label: guide.categoryId,
                    background: theme.colorScheme.primary.withOpacity(0.06),
                    foreground: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                ],
                if (guide.readTimeLabel.isNotEmpty)
                  _Pill(
                    label: guide.readTimeLabel,
                    background:
                        theme.colorScheme.surfaceVariant.withOpacity(0.6),
                    foreground: theme.colorScheme.onSurface.withOpacity(0.8),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (guide.imageUrl != null && guide.imageUrl!.isNotEmpty) ...<Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  guide.imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox.shrink();
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: double.infinity,
                      height: 200,
                      color: theme.colorScheme.surfaceVariant,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                    if (wasSynchronouslyLoaded) return child;
                    return AnimatedOpacity(
                      opacity: frame == null ? 0 : 1,
                      duration: const Duration(milliseconds: 300),
                      child: child,
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              guide.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              guide.body?.isNotEmpty == true
                  ? guide.body!
                  : 'This guide explains key concepts in simple, practical language so you can make informed decisions about your Islamic estate planning. In the full version of this screen, content will be loaded from your CMS or database.',
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

}

class _Pill extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _Pill({
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
      ),
    );
  }
}

