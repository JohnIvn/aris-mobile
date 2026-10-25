import 'package:flutter/material.dart';

import '../services/auth_scope.dart';
import '../services/notifications_scope.dart';
import '../services/notifications_service.dart';
import '../stores/notification_stores.dart';
import '../theme/theme_scope.dart';
import '../widgets/app_bottom_nav.dart';
import 'dtr_screen.dart';
import 'home_screen.dart';
import 'notifications_screen.dart';
import 'payroll_screen.dart';
import 'profile_screen.dart';
import 'reports_screen.dart';

/// Top-level scaffold: owns the bottom nav and swaps between the
/// six main tabs. Deep-linking goes through [goToReports];
/// [goToPayroll] jumps straight to the Payroll tab.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;
  String? _focusedReportId;
  NotificationStore? _notifications;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_notifications == null) {
      final auth = AuthScope.of(context);
      _notifications = NotificationStore(
        NotificationService(tokenProvider: () => auth.token),
      )..load();
    }
  }

  @override
  void dispose() {
    _notifications?.dispose();
    super.dispose();
  }

  void _onTabTap(int i) {
    setState(() {
      _index = i;
      _focusedReportId = null;
    });
    // Refresh on open; items are marked read only when tapped.
    if (i == 4) _notifications!.load();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeScope.colorsOf(context);
    final store = _notifications!;
    final name = AuthScope.of(context).user?.name ?? '';

    final screens = [
      HomeScreen(onSeeReports: goToReports, onSeePayroll: goToPayroll),
      ReportsScreen(focusedReportId: _focusedReportId),
      const DtrScreen(),
      const PayrollScreen(),
      NotificationsScreen(
        onOpenReport: (id) => goToReports(reportId: id),
        onOpenPayroll: goToPayroll,
      ),
      const ProfileScreen(),
    ];

    return NotificationScope(
      store: store,
      child: Scaffold(
        backgroundColor: colors.canvas,
        body: SafeArea(
          bottom: false,
          child: IndexedStack(index: _index, children: screens),
        ),
        bottomNavigationBar: ListenableBuilder(
          listenable: store,
          builder: (context, _) => AppBottomNav(
            currentIndex: _index,
            unreadCount: store.unreadCount,
            profileInitial: name.isEmpty ? '?' : name[0].toUpperCase(),
            onTap: _onTabTap,
          ),
        ),
      ),
    );
  }
}
