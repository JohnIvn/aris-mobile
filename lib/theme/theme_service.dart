import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app_colors.dart';

/// Holds the currently active palette, persists it locally, and notifies
/// listeners on change. Call [load] once in main() before runApp.
class ThemeService extends ChangeNotifier {
  static const _modeKey = 'theme_mode';

  final _storage = const FlutterSecureStorage();

  PaletteMode _mode = PaletteMode.light;

  PaletteMode get mode => _mode;
  AppColors get colors => AppColors.forMode(_mode);

  Future<void> load() async {
    try {
      final saved = await _storage.read(key: _modeKey);
      final match = PaletteMode.values.where((m) => m.name == saved);
      if (match.isNotEmpty && match.first != _mode) {
        _mode = match.first;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('ThemeService.load failed: $e');
    }
  }

  Future<void> setMode(PaletteMode newMode) async {
    if (newMode == _mode) return;
    _mode = newMode;
    notifyListeners();
    try {
      await _storage.write(key: _modeKey, value: newMode.name);
    } catch (e) {
      debugPrint('ThemeService.setMode save failed: $e');
    }
  }
}
