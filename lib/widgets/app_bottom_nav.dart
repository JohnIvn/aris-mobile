import 'package:flutter/material.dart';

import '../theme/theme_scope.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  final int unreadCount;

  /// Letter shown in the profile avatar when there is no [profileAvatarUrl]
  /// (or it fails to load).
  final String profileInitial;

  /// Optional profile picture URL shown in the profile slot.
  final String? profileAvatarUrl;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.unreadCount = 0,
    this.profileInitial = '?',
    this.profileAvatarUrl,
  });

  static const _notificationsIndex = 4;
  static const _profileIndex = 5;

  static const _items = [
    (icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
    (
      icon: Icons.description_outlined,
      activeIcon: Icons.description_rounded,
      label: 'Reports',
    ),
    (
      icon: Icons.access_time_rounded,
      activeIcon: Icons.access_time_filled_rounded,
      label: 'DTR',
    ),
    (
      icon: Icons.payments_outlined,
      activeIcon: Icons.payments_rounded,
      label: 'Payroll',
    ),
    (
      icon: Icons.notifications_outlined,
      activeIcon: Icons.notifications_rounded,
      label: 'Notifications',
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

    // Transparent wrapper: the bar floats over the scaffold background.
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
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

              final label = i == _notificationsIndex && unreadCount > 0
                  ? '${item.label}, $unreadCount unread'
                  : item.label;

              final Color iconColor = selected
                  ? colors.accentActive
                  : colors.text;

              Widget content;
              if (i == _profileIndex) {
                content = Container(
                  width: 32,
                  height: 32,
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
                final icon = Icon(
                  selected ? item.activeIcon : item.icon,
                  size: 24,
                  color: iconColor,
                );
                content = i == _notificationsIndex
                    ? Badge.count(
                        count: unreadCount,
                        isLabelVisible: unreadCount > 0,
                        backgroundColor: colors.error,
                        textColor: Colors.white,
                        child: icon,
                      )
                    : icon;
              }

              return Expanded(
                flex: selected ? 7 : 5,
                child: Semantics(
                  button: true,
                  selected: selected,
                  label: label,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? colors.accent.withValues(alpha: 0.14)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(23),
                        ),
                        child: content,
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
  