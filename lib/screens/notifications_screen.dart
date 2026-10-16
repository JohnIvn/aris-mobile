import 'package:flutter/material.dart';

import '../models/notification_item.dart';
import '../models/status.dart';
import '../services/mock_data_service.dart';
import '../theme/app_colors.dart';
import '../theme/theme_scope.dart';
import '../widgets/section_card.dart';

class NotificationsScreen extends StatelessWidget {
  final void Function(String reportId) onOpenReport;

  const NotificationsScreen({super.key, required this.onOpenReport});

  @override
  Widget build(BuildContext context) {
    final colors = ThemeScope.colorsOf(context);
    final notifications = MockDataService().getNotifications();

    return Container(
      color: colors.canvas,
      child: ListView(
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
          if (notifications.isEmpty)
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
            for (final n in notifications) _notificationTile(colors, n),
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

  Widget _notificationTile(AppColors colors, NotificationItem n) {
    final accent = _kindColor(colors, n.kind);
    final tappable = n.deepLinkReportId != null;

    return SectionCard(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          // No handler (and so no ripple) when there is no report to open.
          onTap: tappable ? () => onOpenReport(n.deepLinkReportId!) : null,
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
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_kindIcon(n.kind), color: accent, size: 20),
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
                          fontWeight: FontWeight.w700,
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
                if (tappable) ...[
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
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${t.month}/${t.day}/${t.year}';
  }
}