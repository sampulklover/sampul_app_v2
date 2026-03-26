import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:sampul_app_v2/l10n/app_localizations.dart';

import '../models/remote_notification.dart';
import '../services/notification_service.dart';
import 'inform_death_management_screen.dart';
import 'hibah_management_screen.dart';
import 'will_management_screen.dart';
import 'executor_management_screen.dart';
import 'trust_management_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late final DateFormat _dateFormatter;
  bool _isLoading = true;
  List<RemoteNotification> _items = const <RemoteNotification>[];

  @override
  void initState() {
    super.initState();
    _dateFormatter = DateFormat.yMMMd().add_jm();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });
    final items = await NotificationService.instance.listUserNotifications();
    if (!mounted) return;
    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  String _formatTimestamp(DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(local.year, local.month, local.day);

    final time = DateFormat.jm().format(local);
    if (date == today) {
      return 'Today • $time';
    }
    if (date == today.subtract(const Duration(days: 1))) {
      return 'Yesterday • $time';
    }
    return '${_dateFormatter.format(local)}';
  }

  Future<void> _handleMarkAllAsRead() async {
    await NotificationService.instance.markAllAsRead();
    await _loadNotifications();
  }

  Future<void> _handleClearAll() async {
    await NotificationService.instance.clearAll();
    await _loadNotifications();
  }

  Future<void> _handleNotificationTap(RemoteNotification n) async {
    await NotificationService.instance.markAsRead(n.id);
    await _loadNotifications();

    // Simple routing based on notification type
    switch (n.type) {
      case 'inform_death_submitted':
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const InformDeathManagementScreen(),
          ),
        );
        break;
      case 'hibah_submitted':
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const HibahManagementScreen(),
          ),
        );
        break;
      case 'will_published':
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const WillManagementScreen(),
          ),
        );
        break;
      case 'executor_created':
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const ExecutorManagementScreen(),
          ),
        );
        break;
      case 'trust_created':
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const TrustManagementScreen(),
          ),
        );
        break;
      default:
        // For now, other types just mark as read and stay on this page.
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.notificationsTitle,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 1,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'mark_all_read') {
                _handleMarkAllAsRead();
              } else if (value == 'clear_all') {
                _handleClearAll();
              }
            },
            itemBuilder: (context) {
              return [
                PopupMenuItem<String>(
                  value: 'mark_all_read',
                  child: Text(l10n.markAllAsRead),
                ),
                PopupMenuItem<String>(
                  value: 'clear_all',
                  child: Text(l10n.clearAll),
                ),
              ];
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        child: Builder(
          builder: (context) {
            if (_isLoading && _items.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_items.isEmpty) {
              // Keep list scrollable so pull-to-refresh still works
              return LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_none,
                              size: 64,
                              color: theme.colorScheme.onSurface.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.noNotifications,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.youAreAllCaughtUp,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final RemoteNotification n = _items[index];
                final bool isUnread = !n.isRead;

                return Dismissible(
                  key: ValueKey<String>(n.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    color: theme.colorScheme.error.withOpacity(0.06),
                    child: Icon(
                      Icons.delete_outline,
                      color: theme.colorScheme.error,
                    ),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(l10n.removeNotificationTitle),
                            content: Text(
                              l10n.removeNotificationDescription,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: Text(l10n.cancel),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: Text(l10n.delete),
                              ),
                            ],
                          ),
                        ) ??
                        false;
                  },
                  onDismissed: (_) async {
                    // Remove locally first to satisfy Dismissible contract
                    setState(() {
                      _items = List<RemoteNotification>.from(_items)
                        ..removeWhere((item) => item.id == n.id);
                    });
                    await NotificationService.instance
                        .deleteNotification(n.id);
                    // Optional: refresh from backend to stay in sync
                    await _loadNotifications();
                  },
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Icon(
                      isUnread
                          ? Icons.notifications_active_outlined
                          : Icons.notifications_none,
                      color: isUnread
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    title: Text(
                      n.title.isNotEmpty ? n.title : l10n.notificationsTitle,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight:
                            isUnread ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (n.body.isNotEmpty) ...[
                          Text(
                            n.body,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        Text(
                          _formatTimestamp(n.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                    trailing: isUnread
                        ? Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          )
                        : null,
                    onTap: () => _handleNotificationTap(n),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

