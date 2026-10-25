import 'package:flutter/material.dart';

import '../models/notification_item.dart';
import '../models/status.dart';
import '../services/notifications_scope.dart';
import '../stores/notification_stores.dart';
import '../theme/app_colors.dart';
import '../theme/theme_scope.dart';
import '../widgets/section_card.dart';

class NotificationsScreen extends StatelessWidget {
  final void Function(String reportId) onOpenReport;
  final VoidCallback onOpenPayroll;

  const NotificationsScreen({
    super.key,
    required this.onOpenReport,
    required this.onOpenPayroll,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeScope.colorsOf(context);
    final store = NotificationScope.of(context);
    final notifications = store.items;

    return Container(
      color: colors.canvas,
      child: RefreshIndicator(
        onRefresh: store.load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            Text(
              'Notifications',
              style: TextStyle(
                color: colors.text,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 16),
            if (!store.hasLoaded && store.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (store.error != null && notifications.isEmpty)
              _errorState(colors, store.error!, store.load)
            else if (notifications.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No notifications yet.',
                    style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  ),
                ),
              )
            else
              for (final n in notifications)
                _notificationTile(colors, store, n),
          ],
        ),
      ),
    );
  }

  Widget _errorState(
    AppColors colors,
    String message,
    Future<void> Function() onRetry,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.error, fontSize: 13),
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }

  Color _kindColor(AppColors colors, StatusColorKind kind) {
    switch (kind) {
      case StatusColorKind.success:
        return colors.success;
      case StatusColorKind.warning:
        return colors.warning;
      case StatusColorKind.error:
        return colors.error;
      case StatusColorKind.info:
        return colors.info;
      case StatusColorKind.neutral:
        return colors.textSecondary;
    }
  }

  IconData _kindIcon(StatusColorKind kind) {
    switch (kind) {
      case StatusColorKind.success:
        return Icons.check_circle_outline;
      case StatusColorKind.warning:
        return Icons.hourglass_empty;
      case StatusColorKind.error:
        return Icons.error_outline;
      case StatusColorKind.info:
        return Icons.info_outline;
      case StatusColorKind.neutral:
        return Icons.notifications_none_rounded;
    }
  }

  Widget _notificationTile(
    AppColors colors,
    NotificationStore store,
    NotificationItem n,
  ) {
    final accent = _kindColor(colors, n.kind);
    final reportId = n.deepLinkReportId;
    final canRedirect = reportId != null || n.opensPayroll;

    // Unread: mark as read. Read: redirect (if there is somewhere to go).
    VoidCallback? onTap;
    if (!n.isRead) {
      onTap = () => store.markRead(n.id);
    } else if (canRedirect) {
      onTap = () {
        if (reportId != null) {
          onOpenReport(reportId);
        } else {
          onOpenPayroll();
        }
      };
    }

    return SectionCard(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: n.isRead ? 0.08 : 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _kindIcon(n.kind),
                    color: n.isRead ? accent.withValues(alpha: 0.6) : accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        n.title,
                        style: TextStyle(
                          color: colors.text,
                          fontWeight: n.isRead
                              ? FontWeight.w500
                              : FontWeight.w700,
                          fontSize: 14.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        n.body,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _relative(n.timestamp),
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!n.isRead) ...[
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: colors.accentActive,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ] else if (canRedirect) ...[
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Icon(
                      Icons.chevron_right,
                      color: colors.textSecondary,
                      size: 20,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _relative(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${t.month}/${t.day}/${t.year}';
  }
}
