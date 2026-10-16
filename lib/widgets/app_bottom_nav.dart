import 'package:flutter/material.dart';

import '../theme/theme_scope.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    (icon: Icons.home_rounded, label: 'Home'),
    (icon: Icons.description_rounded, label: 'Reports'),
    (icon: Icons.access_time_rounded, label: 'DTR'),
    (icon: Icons.payments_rounded, label: 'Payroll'),
    (icon: Icons.notifications_rounded, label: 'Notifications'),
    (icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = ThemeScope.colorsOf(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.bgPrimary,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(_items.length, (i) {
              final selected = i == currentIndex;
              final item = _items[i];
              final color = selected ? colors.accent : colors.textSecondary;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.icon, color: color, size: 24),
                      const SizedBox(height: 2),
                      // Text(
                      //   item.label,
                      //   style: TextStyle(
                      //     color: color,
                      //     fontSize: 11,
                      //     fontWeight:
                      //     selected ? FontWeight.w700 : FontWeight.w400,
                      //   ),
                      // ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
