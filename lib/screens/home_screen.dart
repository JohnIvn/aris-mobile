import 'package:flutter/material.dart';

import '../models/status.dart';
import '../services/mock_data_service.dart';
import '../theme/app_colors.dart';
import '../theme/theme_scope.dart';
import '../widgets/section_card.dart';
import '../widgets/status_badge.dart';

class HomeScreen extends StatelessWidget {
  final void Function({String? reportId}) onSeeReports;

  const HomeScreen({super.key, required this.onSeeReports});

  @override
  Widget build(BuildContext context) {
    final colors = ThemeScope.colorsOf(context);
    final data = MockDataService();
    final reports = data.getReports();
    final latest = reports.first;
    final dtrStage = data.getDtrOverallStage();

    return Container(
      color: colors.bgPrimary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Good morning, ${MockDataService.currentUserName}',
            style: TextStyle(
              color: colors.text,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formattedToday(),
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Current Payroll Period',
            child: Text(
              MockDataService.currentPayrollPeriod,
              style: TextStyle(color: colors.text, fontSize: 14),
            ),
          ),
          SectionCard(
            title: 'Submission Status',
            child: Column(
              children: [
                _statusRow(colors, 'Accomplishment Report', latest.stage),
                const SizedBox(height: 8),
                _statusRow(colors, 'DTR', dtrStage),
                const SizedBox(height: 8),
                _statusRow(colors, 'Payroll', PipelineStage.accounting),
              ],
            ),
          ),
          SectionCard(
            title: 'Next Action',
            child: Row(
              children: [
                Icon(Icons.check_circle_outline,
                    color: colors.accent, size: 18),
                const SizedBox(width: 8),
                Text(
                  'No action required',
                  style: TextStyle(color: colors.text, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => onSeeReports(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'View all reports',
                  style: TextStyle(
                    color: colors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(Icons.arrow_forward, color: colors.accent, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusRow(AppColors colors, String label, PipelineStage stage) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.text, fontSize: 14)),
        StatusBadge(label: stage.label, kind: stage.colorKind),
      ],
    );
  }

  String _formattedToday() {
    final now = DateTime.now();
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }
}
