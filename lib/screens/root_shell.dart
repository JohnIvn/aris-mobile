import 'package:flutter/material.dart';

import '../services/auth_scope.dart';
import '../services/mock_data_service.dart';
import '../theme/theme_scope.dart';
import '../widgets/app_bottom_nav.dart';
import 'dtr_screen.dart';
import 'home_screen.dart';
import 'notifications_screen.dart';
import 'payroll_screen.dart';
import 'profile_screen.dart';
import 'reports_screen.dart';

/// Top-level scaffold: owns the bottom nav and swaps between the
/// six main tabs. Deep-linking (e.g. from a notification into a
/// specific report) goes through [goToReports]; [goToPayroll] jumps
/// straight to the Payroll tab.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;
  String? _focusedReportId;

  /// Notification ids the user has already seen this session. The
  /// model has no read flag yet, so the nav badge counts everything
  /// not in this set. Swap for a real `isRead` once it exists.
  final Set<String> _seenNotificationIds = {};

  void goToReports({String? reportId}) {
    setState(() {
      _index = 1;
      _focusedReportId = reportId;
    });
  }

  void goToPayroll() {
    setState(() {
      _index = 3;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeScope.colorsOf(context);
    final notifications = MockDataService().getNotifications();
    final unread = notifications
        .where((n) => !_seenNotificationIds.contains(n.id))
        .length;
    final name = AuthScope.of(context).user?.name ?? '';

    final screens = [
      HomeScreen(onSeeReports: goToReports, onSeePayroll: goToPayroll),
      ReportsScreen(focusedReportId: _focusedReportId),
      const DtrScreen(),
      const PayrollScreen(),
      NotificationsScreen(onOpenReport: (id) => goToReports(reportId: id)),
      const ProfileScreen(),
    ];

    return Scaffold(
      // Every tab now sits on the off-white canvas, so the strip behind
      // the status bar and the floating nav match the page.
      backgroundColor: colors.canvas,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _index, children: screens),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _index,
        unreadCount: unread,
        profileInitial: name.isEmpty ? '?' : name[0].toUpperCase(),
        onTap: (i) => setState(() {
          _index = i;
          _focusedReportId = null;
          if (i == 4) {
            _seenNotificationIds.addAll(notifications.map((n) => n.id));
          }
        }),
      ),
    );
  }
}
