import 'package:flutter/material.dart';

import '../models/status.dart';
import '../services/auth_scope.dart';
import '../theme/app_colors.dart';
import '../theme/theme_scope.dart';
import '../widgets/section_card.dart';
import '../widgets/status_badge.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static String _s(Object? v) {
    final s = v?.toString().trim() ?? '';
    return s.isEmpty ? '—' : s;
  }

  static String _date(Object? v) {
    final s = _s(v);
    return s.contains('T') ? s.split('T').first : s;
  }

  static String _cap(String s) =>
      s.isEmpty ? '—' : s[0].toUpperCase() + s.substring(1);

  Future<void> _confirmSignOut(BuildContext context) async {
    final colors = ThemeScope.colorsOf(context);
    final auth = AuthScope.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Sign out?',
          style: TextStyle(
            color: colors.text,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'You will need to sign in again to access your account.',
          style: TextStyle(color: colors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: colors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Sign out',
              style: TextStyle(
                color: colors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      auth.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeScope.colorsOf(context);
    final auth = AuthScope.of(context);
    final user = auth.user;
    final raw = user?.raw ?? const <String, dynamic>{};

    final name = user?.name ?? '';
    final email = user?.email;
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();
    final avatarUrl = user?.avatarUrl;

    final initialAvatar = Text(
      initial,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 26,
        fontWeight: FontWeight.w700,
      ),
    );

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
                  child: avatarUrl != null && avatarUrl.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            avatarUrl,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => initialAvatar,
                          ),
                        )
                      : initialAvatar,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _s(name),
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
            child: _infoRows(
              colors,
              [
                ('Name', _s(name)),
                ('Middle name', _s(raw['middlename'])),
                ('Username', _s(user?.username)),
                ('Role', _cap(user?.role ?? '')),
                ('Employee/Professor ID', _s(user?.employeeId)),
                ('Department', _s(user?.department)),
                ('Position', _s(user?.position)),
                ('Birthday', _date(raw['birthday'])),
                ('Age', _s(raw['age'])),
                (
                  'Gender',
                  _cap(_s(raw['gender']) == '—' ? '' : _s(raw['gender'])),
                ),
                ('Email', email ?? '—'),
              ],
              wrappable: const {'Department'},
            ),
          ),
          // SectionCard(
          //   title: 'Employment Information',
          //   child: _infoRows(colors, [
          //     ('Salary type', '—'),
          //     ('Shift', '—'),
          //     ('Employment status', '—'),
          //   ]),
          // ),
          SectionCard(
            title: 'Preferences',
            child: _navRow(
              colors,
              icon: Icons.palette_outlined,
              title: 'Appearance & Notifications',
              subtitle: 'Theme, color mode, notification types',
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
          ),
          SectionCard(
            title: 'Account',
            child: _navRow(
              colors,
              icon: Icons.verified_user_outlined,
              title: 'OAuth account',
              subtitle: email,
              trailing: user != null
                  ? StatusBadge(
                      label: user.provider,
                      kind: StatusColorKind.neutral,
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () => _confirmSignOut(context),
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

  /// Labels keep their natural width; values fill the rest on one line.
  /// Only labels listed in [wrappable] may wrap (up to 3 lines).
  Widget _infoRows(
    AppColors colors,
    List<(String, String)> rows, {
    Set<String> wrappable = const {},
  }) {
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
      final canWrap = wrappable.contains(label);
      children.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              softWrap: false,
              style: TextStyle(color: colors.textSecondary, fontSize: 13.5),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                maxLines: canWrap ? 3 : 1,
                softWrap: canWrap,
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
