import 'package:flutter/material.dart';

import '../models/status.dart';
import '../services/auth_scope.dart';
import '../services/mock_data_service.dart';
import '../theme/app_colors.dart';
import '../theme/theme_scope.dart';
import '../widgets/section_card.dart';
import '../widgets/status_badge.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = ThemeScope.colorsOf(context);
    final auth = AuthScope.of(context);

    final name = auth.user?.name ?? MockDataService.currentUserName;
    final email = auth.user?.email;
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();

    return Container(
      color: colors.canvas,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          Text(
            'Profile',
            style: TextStyle(
              color: colors.text,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.accentActive,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.text,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (email != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          SectionCard(
            title: 'Personal Information',
            child: _infoRows(colors, [
              ('Name', name),
              ('Employee/Professor ID', '—'),
              ('Department', '—'),
              ('Position', '—'),
              ('Email', email ?? '—'),
            ]),
          ),

          SectionCard(
            title: 'Employment Information',
            child: _infoRows(colors, [
              ('Salary type', '—'),
              ('Shift', '—'),
              ('Employment status', '—'),
            ]),
          ),
          SectionCard(
            title: 'Preferences',
            child: _navRow(
              colors,
              icon: Icons.palette_outlined,
              title: 'Appearance & Notifications',
              subtitle: 'Theme, color mode, notification types',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
          ),
          SectionCard(
            title: 'Account',
            child: _navRow(
              colors,
              icon: Icons.verified_user_outlined,
              title: 'OAuth account',
              subtitle: email,
              trailing: auth.user != null
                  ? StatusBadge(
                      label: auth.user!.provider,
                      kind: StatusColorKind.neutral,
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: auth.signOut,
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: const Text('Sign out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.error,
                backgroundColor: colors.surface,
                side: BorderSide(color: colors.error.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _infoRows(AppColors colors, List<(String, String)> rows) {
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      if (i > 0) {
        children.add(
          Divider(
            height: 24,
            thickness: 1,
            color: colors.border.withValues(alpha: 0.5),
          ),
        );
      }
      final (label, value) = rows[i];
      final empty = value == '—';
      children.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Text(
                label,
                style: TextStyle(color: colors.textSecondary, fontSize: 13.5),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 4,
              child: Text(
                value,
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: empty ? colors.textSecondary : colors.text,
                  fontSize: 13.5,
                  fontWeight: empty ? FontWeight.w400 : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Column(children: children);
  }

  /// Row with a tinted icon tile. Tappable (with a chevron) when
  /// [onTap] is given; otherwise a static row with an optional trailing.
  Widget _navRow(
    AppColors colors, {
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    final row = Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colors.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: colors.accentActive),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: colors.text,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: colors.textSecondary, fontSize: 12.5),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing],
        if (onTap != null)
          Icon(Icons.chevron_right, color: colors.textSecondary),
      ],
    );

    if (onTap == null) return row;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: row,
      ),
    );
  }
}