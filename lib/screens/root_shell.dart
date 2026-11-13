import 'package:flutter/material.dart';

import '../services/auth_scope.dart';
import '../services/notifications_scope.dart';
import '../services/notifications_service.dart';
import '../stores/notification_stores.dart';
import '../theme/theme_scope.dart';
import '../widgets/app_bottom_nav.dart';
import 'home_screen.dart';
import 'notifications_screen.dart';
import 'payroll_screen.dart';
import 'profile_screen.dart';
import 'reports_screen.dart';
import 'submit_screen.dart';

/// Top-level scaffold: owns the 5-item bottom nav and swaps between
/// Home, Reports (Current + Records), Payroll, Submit, and Profile.
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
      _index = 2;
    });
  }

  void _openNotifications() {
    final store = _notifications!;
    store.load();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotificationScope(
          store: store,
          child: NotificationsScreen(
            onOpenReport: (id) {
              Navigator.of(context).pop();
              goToReports(reportId: id);
            },
            onOpenPayroll: () {
              Navigator.of(context).pop();
              goToPayroll();
            },
          ),
        ),
      ),
    );
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
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeScope.colorsOf(context);
    final store = _notifications!;
    final user = AuthScope.of(context).user;
    final name = user?.name ?? '';

    final screens = [
      HomeScreen(
        notificationStore: store,
        onSeeReports: goToReports,
        onSeePayroll: goToPayroll,
        onSeeNotifications: _openNotifications,
      ),
      ReportsScreen(focusedReportId: _focusedReportId),
      const PayrollScreen(),
      const SubmitScreen(),
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
        bottomNavigationBar: AppBottomNav(
          currentIndex: _index,
          profileInitial: name.isEmpty ? '?' : name[0].toUpperCase(),
          profileAvatarUrl: user?.avatarUrl,
          onTap: _onTabTap,
        ),
      ),
    );
  }
}