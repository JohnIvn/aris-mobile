import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'theme_service.dart';

/// Makes the active [AppColors] available anywhere below it via
/// ThemeScope.of(context) / ThemeScope.colorsOf(context), and
/// rebuilds automatically whenever ThemeService changes mode.
class ThemeScope extends InheritedNotifier<ThemeService> {
  const ThemeScope({
    super.key,
    required ThemeService themeService,
    required super.child,
  }) : super(notifier: themeService);

  static ThemeService of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeScope>();
    assert(scope != null, 'ThemeScope not found in widget tree');
    return scope!.notifier!;
  }

  static AppColors colorsOf(BuildContext context) => of(context).colors;
}
