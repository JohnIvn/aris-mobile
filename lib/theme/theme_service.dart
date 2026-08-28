import 'package:flutter/foundation.dart';

import 'app_colors.dart';

/// Holds the currently active palette and notifies listeners on
/// change. Swap this for a version backed by shared_preferences /
/// the DB once persistence is wired up — the rest of the app only
/// ever talks to this class, never to raw colors.
class ThemeService extends ChangeNotifier {
  PaletteMode _mode = PaletteMode.light;

  PaletteMode get mode => _mode;
  AppColors get colors => AppColors.forMode(_mode);

  void setMode(PaletteMode newMode) {
    if (newMode == _mode) return;
    _mode = newMode;
    notifyListeners();
  }
}
