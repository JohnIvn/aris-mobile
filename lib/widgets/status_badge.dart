import 'package:flutter/material.dart';

import '../models/status.dart';
import '../theme/app_colors.dart';
import '../theme/theme_scope.dart';
class StatusBadge extends StatelessWidget {
  final String label;
  final StatusColorKind kind;

  const StatusBadge({super.key, required this.label, required this.kind});

  Color _colorFor(AppColors c, StatusColorKind kind) {
    switch (kind) {
      case StatusColorKind.success:
        return c.success;
      case StatusColorKind.warning:
        return c.warning;
      case StatusColorKind.error:
        return c.error;
      case StatusColorKind.info:
        return c.info;
      case StatusColorKind.neutral:
        return c.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeScope.colorsOf(context);
    final color = _colorFor(colors, kind);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}