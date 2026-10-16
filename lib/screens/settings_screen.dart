import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/theme_scope.dart';
import '../widgets/section_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = ThemeScope.colorsOf(context);
    final themeService = ThemeScope.of(context);

    return Scaffold(
      backgroundColor: colors.canvas,
      appBar: AppBar(
        backgroundColor: colors.canvas,
        foregroundColor: colors.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: const Text(
          'Appearance',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          SectionCard(
            title: 'Color Mode',
            child: Column(
              children: [
                for (var i = 0; i < PaletteMode.values.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  _modeRow(
                    colors,
                    PaletteMode.values[i],
                    PaletteMode.values[i] == themeService.mode,
                    () => themeService.setMode(PaletteMode.values[i]),
                  ),
                ],
              ],
            ),
          ),
          SectionCard(
            title: 'Preview',
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                _swatch(colors, 'Accent', colors.accent),
                _swatch(colors, 'Success', colors.success),
                _swatch(colors, 'Warning', colors.warning),
                _swatch(colors, 'Error', colors.error),
                _swatch(colors, 'Info', colors.info),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeRow(
    AppColors colors,
    PaletteMode mode,
    bool selected,
    VoidCallback onTap,
  ) {
    return Semantics(
      button: true,
      selected: selected,
      label: mode.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: selected
                  ? colors.accent.withValues(alpha: 0.10)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? colors.accentActive.withValues(alpha: 0.5)
                    : colors.border.withValues(alpha: 0.6),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mode.label,
                        style: TextStyle(
                          color: colors.text,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        mode.description,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  color: selected
                      ? colors.accentActive
                      : colors.textSecondary.withValues(alpha: 0.6),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _swatch(AppColors colors, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: colors.border),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
      ],
    );
  }
}