import 'package:flutter/material.dart';

class ProfileDetailItem {
  final IconData icon;
  final String label;
  final String value;

  const ProfileDetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  String get displayValue => value.trim().isEmpty ? 'Not provided' : value.trim();
}

class ProfileDetailsCard extends StatelessWidget {
  final String title;
  final List<ProfileDetailItem> items;
  final VoidCallback? onEdit;
  final EdgeInsetsGeometry padding;

  const ProfileDetailsCard({
    super.key,
    required this.title,
    required this.items,
    this.onEdit,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                if (onEdit != null)
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit profile'),
                    style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ...items.map((ProfileDetailItem item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(item.icon, size: 20, color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              item.label,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.displayValue,
                              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

