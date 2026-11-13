import 'package:flutter/material.dart';

import '../models/notification_item.dart';
import '../models/status.dart';
import '../services/notifications_scope.dart';
import '../stores/notification_stores.dart';
import '../theme/app_colors.dart';
import '../theme/theme_scope.dart';
import '../widgets/section_card.dart';

class NotificationsScreen extends StatefulWidget {
  final void Function(String reportId) onOpenReport;
  final VoidCallback onOpenPayroll;

  const NotificationsScreen({
    super.key,
    required this.onOpenReport,
    required this.onOpenPayroll,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _unreadOnly = false;

  @override
  Widget build(BuildContext context) {
    final colors = ThemeScope.colorsOf(context);
    final store = NotificationScope.of(context);

    return Scaffold(
      backgroundColor: colors.canvas,
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            final all = store.items;
            final unreadCount = store.unreadCount;
            final visible = _unreadOnly
                ? all.where((n) => !n.isRead).toList()
                : all;

            return Column(
              children: [
                _header(context, colors, store, unreadCount),
                if (all.isNotEmpty)
                  _filterBar(colors, total: all.length, unread: unreadCount),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: store.load,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                      children: [
                        if (!store.hasLoaded && store.isLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 48),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (store.error != null && all.isEmpty)
                          _errorState(colors, store.error!, store.load)
                        else if (visible.isEmpty)
                          _emptyState(colors, isFiltered: _unreadOnly && all.isNotEmpty)
                        else
                          ..._groupedNotifications(colors, store, visible),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _header(
    BuildContext context,
    AppColors colors,
    NotificationStore store,
    int unreadCount,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 20, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: colors.text,
              size: 20,
            ),
            tooltip: 'Back',
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    'Notifications',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                if (unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colors.accentActive,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (unreadCount > 0)
            TextButton.icon(
              onPressed: store.markAllRead,
              style: TextButton.styleFrom(
                foregroundColor: colors.accentActive,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.done_all_rounded, size: 18),
              label: const Text(
                'Mark all read',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }

  Widget _filterBar(
    AppColors colors, {
    required int total,
    required int unread,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
      child: Row(
        children: [
          _filterChip(
            colors,
            label: 'All ($total)',
            selected: !_unreadOnly,
            onTap: () => setState(() => _unreadOnly = false),
          ),
          const SizedBox(width: 8),
          _filterChip(
            colors,
            label: 'Unread ($unread)',
            selected: _unreadOnly,
            onTap: () => setState(() => _unreadOnly = true),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(
    AppColors colors, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? colors.accent.withValues(alpha: 0.14)
                  : colors.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected
                    ? colors.accentActive.withValues(alpha: 0.5)
                    : colors.border.withValues(alpha: 0.6),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? colors.accentActive : colors.textSecondary,
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _groupedNotifications(
    AppColors colors,
    NotificationStore store,
    List<NotificationItem> items,
  ) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));

    final today = <NotificationItem>[];
    final yesterday = <NotificationItem>[];
    final earlier = <NotificationItem>[];

    for (final item in items) {
      if (!item.timestamp.isBefore(todayStart)) {
        today.add(item);
      } else if (!item.timestamp.isBefore(yesterdayStart)) {
        yesterday.add(item);
      } else {
        earlier.add(item);
      }
    }

    final widgets = <Widget>[];

    void addGroup(String title, List<NotificationItem> group) {
      if (group.isEmpty) return;
      if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 8));
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10, top: 4),
          child: Text(
            title,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
      );
      for (final n in group) {
        widgets.add(_notificationTile(colors, store, n));
      }
    }

    addGroup('Today', today);
    addGroup('Yesterday', yesterday);
    addGroup('Earlier', earlier);

    return widgets;
  }

  Widget _emptyState(AppColors colors, {required bool isFiltered}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: colors.accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isFiltered
                  ? Icons.check_circle_outline_rounded
                  : Icons.notifications_none_rounded,
              color: colors.accentActive,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isFiltered ? "You're all caught up!" : 'No notifications yet',
            style: TextStyle(
              color: colors.text,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isFiltered
                ? 'You have no unread notifications right now.'
                : 'Updates about your AR, DTR, and payroll will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorState(
    AppColors colors,
    String message,
    Future<void> Function() onRetry,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      child: Column(
        children: [
          Icon(Icons.wifi_off_rounded, color: colors.error, size: 32),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.error, fontSize: 13),
          ),
          const SizedBox(height: 14),
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

  IconData _iconFor(NotificationItem n) {
    if (n.opensPayroll) {
      return n.kind == StatusColorKind.error
          ? Icons.money_off_csred_rounded
          : Icons.payments_outlined;
    }
    switch (n.type) {
      case 'ar_approved':
        return Icons.check_circle_outline_rounded;
      case 'ar_rejected':
      case 'ar_returned':
        return Icons.error_outline_rounded;
      case 'ar_submitted':
        return Icons.upload_file_outlined;
      default:
        switch (n.kind) {
          case StatusColorKind.success:
            return Icons.check_circle_outline_rounded;
          case StatusColorKind.warning:
            return Icons.hourglass_bottom_rounded;
          case StatusColorKind.error:
            return Icons.error_outline_rounded;
          case StatusColorKind.info:
            return Icons.info_outline_rounded;
          case StatusColorKind.neutral:
            return Icons.notifications_none_rounded;
        }
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
    final isUnread = !n.isRead;

    VoidCallback? onTap;
    if (isUnread || canRedirect) {
      onTap = () {
        if (isUnread) {
          store.markRead(n.id);
        }
        if (reportId != null) {
          widget.onOpenReport(reportId);
        } else if (n.opensPayroll) {
          widget.onOpenPayroll();
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
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: isUnread
                ? BoxDecoration(
                    color: colors.accent.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colors.accentActive.withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                  )
                : null,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: isUnread ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    _iconFor(n),
                    color: isUnread ? accent : accent.withValues(alpha: 0.7),
                    size: 21,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              n.title,
                              style: TextStyle(
                                color: colors.text,
                                fontWeight:
                                    isUnread ? FontWeight.w700 : FontWeight.w600,
                                fontSize: 14.5,
                              ),
                            ),
                          ),
                          if (isUnread) ...[
                            const SizedBox(width: 8),
                            Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: Container(
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                  color: colors.accentActive,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (n.body.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          n.body,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 13,
                            color: colors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _relative(n.timestamp),
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          if (canRedirect) ...[
                            const Spacer(),
                            Text(
                              reportId != null ? 'View report' : 'View payroll',
                              style: TextStyle(
                                color: colors.accentActive,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: colors.accentActive,
                              size: 16,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
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