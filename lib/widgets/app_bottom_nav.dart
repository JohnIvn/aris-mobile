import 'package:flutter/material.dart';

import '../theme/theme_scope.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Letter shown in the profile avatar when there is no [profileAvatarUrl]
  /// (or it fails to load).
  final String profileInitial;

  /// Optional profile picture URL shown in the profile slot.
  final String? profileAvatarUrl;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.profileInitial = '?',
    this.profileAvatarUrl,
  });

  static const _profileIndex = 4;

  static const _items = [
    (icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
    (
      icon: Icons.description_outlined,
      activeIcon: Icons.description_rounded,
      label: 'Reports',
    ),
    (
      icon: Icons.payments_outlined,
      activeIcon: Icons.payments_rounded,
      label: 'Payroll',
    ),
    (
      icon: Icons.send_outlined,
      activeIcon: Icons.send_rounded,
      label: 'Submit',
    ),
    (
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = ThemeScope.colorsOf(context);
    final avatarUrl = profileAvatarUrl;
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

    final initialAvatar = Text(
      profileInitial,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: colors.border.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: List.generate(_items.length, (i) {
              final selected = i == currentIndex;
              final item = _items[i];
              final Color iconColor = selected
                  ? colors.accentActive
                  : colors.text;

              Widget iconWidget;
              if (i == _profileIndex) {
                iconWidget = Container(
                  width: 30,
                  height: 30,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: iconColor, width: 2),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.accentActive,
                    ),
                    child: hasAvatar
                        ? ClipOval(
                            child: Image.network(
                              avatarUrl,
                              width: 24,
                              height: 24,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => initialAvatar,
                            ),
                          )
                        : initialAvatar,
                  ),
                );
              } else {
                iconWidget = Icon(
                  selected ? item.activeIcon : item.icon,
                  size: 24,
                  color: iconColor,
                );
              }

              return Expanded(
                child: Semantics(
                  button: true,
                  selected: selected,
                  label: item.label,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? colors.accent.withValues(alpha: 0.14)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: iconWidget,
                      ),
                    ),
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