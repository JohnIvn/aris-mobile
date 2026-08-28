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
      color: colors.bgPrimary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Notifications',
            style: TextStyle(
                color: colors.text, fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          for (final n in notifications) _notificationTile(colors, n),
        ],
      ),
    );
  }

  Widget _notificationTile(AppColors colors, NotificationItem n) {
    Color dotColor;
    switch (n.kind) {
      case StatusColorKind.success:
        dotColor = colors.success;
        break;
      case StatusColorKind.warning:
        dotColor = colors.warning;
        break;
      case StatusColorKind.error:
        dotColor = colors.error;
        break;
      case StatusColorKind.info:
        dotColor = colors.info;
        break;
      case StatusColorKind.neutral:
        dotColor = colors.textSecondary;
        break;
    }

    return InkWell(
      onTap: n.deepLinkReportId != null
          ? () => onOpenReport(n.deepLinkReportId!)
          : null,
      borderRadius: BorderRadius.circular(14),
      child: SectionCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 5, right: 10),
              decoration:
                  BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(n.title,
                      style: TextStyle(
                          color: colors.text,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  const SizedBox(height: 3),
                  Text(n.body,
                      style:
                          TextStyle(color: colors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(_relative(n.timestamp),
                      style:
                          TextStyle(color: colors.textSecondary, fontSize: 11)),
                ],
              ),
            ),
          ],
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
