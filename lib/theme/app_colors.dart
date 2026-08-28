import 'package:flutter/material.dart';

/// Available color palette modes the user can switch between in
/// Settings. Persisted later once the DB layer exists.
enum PaletteMode { light, dark, inverted, colorBlind }

extension PaletteModeLabel on PaletteMode {
  String get label {
    switch (this) {
      case PaletteMode.light:
        return 'Light';
      case PaletteMode.dark:
        return 'Dark';
      case PaletteMode.inverted:
        return 'Inverted';
      case PaletteMode.colorBlind:
        return 'Color Blind Friendly';
    }
  }

  String get description {
    switch (this) {
      case PaletteMode.light:
        return 'Default light theme';
      case PaletteMode.dark:
        return 'Dark background, light text';
      case PaletteMode.inverted:
        return 'Fully inverted palette';
      case PaletteMode.colorBlind:
        return 'Deuteranopia-safe status colors';
    }
  }
}

/// Immutable bundle of all colors ARIS uses. Swap the active
/// instance to re-theme the whole app; screens/widgets should
/// only ever read AppColors fields, never a raw hex value.
@immutable
class AppColors {
  final PaletteMode mode;

  final Color bgPrimary;
  final Color bgSecondary;
  final Color bgTertiary;

  final Color text;
  final Color textSecondary;

  final Color accent;
  final Color accentHover;
  final Color accentActive;

  final Color border;

  final Color success;
  final Color warning;
  final Color error;
  final Color info;

  const AppColors({
    required this.mode,
    required this.bgPrimary,
    required this.bgSecondary,
    required this.bgTertiary,
    required this.text,
    required this.textSecondary,
    required this.accent,
    required this.accentHover,
    required this.accentActive,
    required this.border,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
  });

  /// Original palette as specified for ARIS.
  static const AppColors light = AppColors(
    mode: PaletteMode.light,
    bgPrimary: Color(0xFFFFFFFF),
    bgSecondary: Color(0xFFF5F5F5),
    bgTertiary: Color(0xFFEDEDED),
    text: Color(0xFF000000),
    textSecondary: Color(0xFF666666),
    accent: Color(0xFF4FAE4A),
    accentHover: Color(0xFF449742),
    accentActive: Color(0xFF377B36),
    border: Color(0xFFD6D6D6),
    success: Color(0xFF4CAF50),
    warning: Color(0xFFD4A017),
    error: Color(0xFFC94A4A),
    info: Color(0xFF3B82C4),
  );

  /// Dark mode: keeps the same accent hue but lifts it slightly so
  /// it still reads clearly on near-black backgrounds.
  static const AppColors dark = AppColors(
    mode: PaletteMode.dark,
    bgPrimary: Color(0xFF121212),
    bgSecondary: Color(0xFF1C1C1C),
    bgTertiary: Color(0xFF262626),
    text: Color(0xFFF2F2F2),
    textSecondary: Color(0xFFA6A6A6),
    accent: Color(0xFF5FC15A),
    accentHover: Color(0xFF4FAE4A),
    accentActive: Color(0xFF449742),
    border: Color(0xFF3A3A3A),
    success: Color(0xFF5DBF59),
    warning: Color(0xFFE0B23A),
    error: Color(0xFFD46A6A),
    info: Color(0xFF5C9FD6),
  );

  /// True mathematical inversion (255 - channel) of [light],
  /// distinct from [dark] because it flips the accent hue too,
  /// not just the neutrals.
  static AppColors get inverted => _invert(light);

  static AppColors _invert(AppColors base) {
    Color inv(Color c) => Color.fromARGB(
          c.alpha,
          255 - c.red,
          255 - c.green,
          255 - c.blue,
        );
    return AppColors(
      mode: PaletteMode.inverted,
      bgPrimary: inv(base.bgPrimary),
      bgSecondary: inv(base.bgSecondary),
      bgTertiary: inv(base.bgTertiary),
      text: inv(base.text),
      textSecondary: inv(base.textSecondary),
      accent: inv(base.accent),
      accentHover: inv(base.accentHover),
      accentActive: inv(base.accentActive),
      border: inv(base.border),
      success: inv(base.success),
      warning: inv(base.warning),
      error: inv(base.error),
      info: inv(base.info),
    );
  }

  /// Deuteranopia/protanopia-safe status colors (Okabe-Ito
  /// palette), since green/red/orange are what collide for most
  /// color-blind users. Accent switches from green to blue too,
  /// since it doubles as a status/affordance color in a few places.
  static const AppColors colorBlind = AppColors(
    mode: PaletteMode.colorBlind,
    bgPrimary: Color(0xFFFFFFFF),
    bgSecondary: Color(0xFFF5F5F5),
    bgTertiary: Color(0xFFEDEDED),
    text: Color(0xFF000000),
    textSecondary: Color(0xFF666666),
    accent: Color(0xFF0072B2),
    accentHover: Color(0xFF005A8C),
    accentActive: Color(0xFF00436A),
    border: Color(0xFFD6D6D6),
    success: Color(0xFF0072B2),
    warning: Color(0xFFE69F00),
    error: Color(0xFFD55E00),
    info: Color(0xFF56B4E9),
  );

  static AppColors forMode(PaletteMode mode) {
    switch (mode) {
      case PaletteMode.light:
        return light;
      case PaletteMode.dark:
        return dark;
      case PaletteMode.inverted:
        return inverted;
      case PaletteMode.colorBlind:
        return colorBlind;
    }
  }
}
