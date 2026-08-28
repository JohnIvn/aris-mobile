import 'package:flutter/material.dart';

import '../services/auth_scope.dart';
import '../services/mock_data_service.dart';
import '../theme/app_colors.dart';
import '../theme/theme_scope.dart';
import '../widgets/section_card.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = ThemeScope.colorsOf(context);
    final auth = AuthScope.of(context);

    return Container(
      color: colors.bgPrimary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Profile',
              style: TextStyle(
                  color: colors.text, fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Personal Information',
            child: Column(
              children: [
                _infoRow(colors, 'Name', MockDataService.currentUserName),
                _infoRow(colors, 'Employee/Professor ID', '—'),
                _infoRow(colors, 'Department', '—'),
                _infoRow(colors, 'Position', '—'),
                _infoRow(colors, 'Email', '—'),
              ],
            ),
          ),
          // Salary intentionally omitted here — see the doc's note
          // on not surfacing it on Profile; move it under a
          // dedicated Payroll view if/when that's needed.
          SectionCard(
            title: 'Employment Information',
            child: Column(
              children: [
                _infoRow(colors, 'Salary type', '—'),
                _infoRow(colors, 'Shift', '—'),
                _infoRow(colors, 'Employment status', '—'),
              ],
            ),
          ),
          SectionCard(
            title: 'Preferences',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Appearance & Notifications',
                  style: TextStyle(color: colors.text)),
              subtitle: Text('Theme, color mode, notification types',
                  style:
                      TextStyle(color: colors.textSecondary, fontSize: 12)),
              trailing: Icon(Icons.chevron_right, color: colors.textSecondary),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
          ),
          SectionCard(
            title: 'Account',
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('OAuth account', style: TextStyle(color: colors.text)),
                  subtitle: auth.user != null
                      ? Text(auth.user!.email,
                          style: TextStyle(
                              color: colors.textSecondary, fontSize: 12))
                      : null,
                  trailing:
                      Icon(Icons.chevron_right, color: colors.textSecondary),
                  onTap: () {},
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Sign out', style: TextStyle(color: colors.error)),
                  onTap: auth.signOut,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(AppColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          Text(value,
              style: TextStyle(
                  color: colors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
