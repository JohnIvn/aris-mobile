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
      backgroundColor: colors.bgPrimary,
      appBar: AppBar(
        backgroundColor: colors.bgPrimary,
        foregroundColor: colors.text,
        elevation: 0,
        title: const Text('Appearance'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            title: 'Color Mode',
            padding: EdgeInsets.zero,
            child: Column(
              children: PaletteMode.values.map((mode) {
                final selected = mode == themeService.mode;
                return RadioListTile<PaletteMode>(
                  value: mode,
                  groupValue: themeService.mode,
                  activeColor: colors.accent,
                  onChanged: (m) => themeService.setMode(m!),
                  title: Text(mode.label, style: TextStyle(color: colors.text)),
                  subtitle: Text(mode.description,
                      style:
                          TextStyle(color: colors.textSecondary, fontSize: 12)),
                  selected: selected,
                );
              }).toList(),
            ),
          ),
          SectionCard(
            title: 'Preview',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
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
