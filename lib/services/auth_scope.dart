import 'package:flutter/material.dart';

import 'auth_service.dart';

/// Same pattern as ThemeScope — makes the active [AuthService]
/// available anywhere below it via AuthScope.of(context), and
/// rebuilds automatically on sign-in/sign-out.
class AuthScope extends InheritedNotifier<AuthService> {
  const AuthScope({
    super.key,
    required AuthService authService,
    required super.child,
  }) : super(notifier: authService);

  static AuthService of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope not found in widget tree');
    return scope!.notifier!;
  }
}
