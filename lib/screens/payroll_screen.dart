import 'package:flutter/material.dart';

import '../models/report_item.dart';
import '../models/status.dart';
import '../services/mock_data_service.dart';
import '../theme/app_colors.dart';
import '../theme/theme_scope.dart';
import '../widgets/section_card.dart';
import '../widgets/status_badge.dart';
import 'report_detail_screen.dart';

class PayrollScreen extends StatelessWidget {
  const PayrollScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = ThemeScope.colorsOf(context);
    final reports = MockDataService().getReports();

    final available = reports
        .where((r) => r.payrollStatus == PayrollStatus.available)
        .length;
    final received =
        reports.where((r) => r.payrollStatus == PayrollStatus.received).length;
    final pending = reports
        .where((r) => r.payrollStatus == PayrollStatus.notAvailable)
        .length;

    return Container(
      color: colors.bgPrimary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Payroll',
            style: TextStyle(
              color: colors.text,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Unlocks once Department, HR, and Accounting have all '
                'verified a period\'s AR & DTR.',
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Overview',
            child: Row(
              children: [
                Expanded(
                  child: _overviewStat(
                      colors, 'Available', available, colors.info),
                ),
                Container(width: 1, height: 40, color: colors.border),
                Expanded(
                  child: _overviewStat(
                      colors, 'Received', received, colors.success),
                ),
                Container(width: 1, height: 40, color: colors.border),
                Expanded(
                  child: _overviewStat(
                      colors, 'Pending', pending, colors.textSecondary),
                ),
              ],
            ),
          ),
          for (final report in reports) _payrollTile(context, colors, report),
        ],
      ),
    );
  }

  Widget _overviewStat(
      AppColors colors,
      String label,
      int value,
      Color valueColor,
      ) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
              color: valueColor, fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
      ],
    );
  }

  Widget _payrollTile(BuildContext context, AppColors colors, ReportItem report) {
    late final String subtitle;
    if (report.payrollStatus == PayrollStatus.received &&
        report.payrollReceivedAt != null) {
      subtitle = 'Received ${_formatDate(report.payrollReceivedAt!)}';
    } else if (report.payrollStatus == PayrollStatus.available &&
        report.payrollAvailableAt != null) {
      subtitle = 'Available since ${_formatDate(report.payrollAvailableAt!)}';
    } else {
      subtitle = 'Awaiting full AR & DTR verification';
    }

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ReportDetailScreen(report: report)),
      ),
      child: SectionCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.periodLabel,
                    style: TextStyle(
                        color: colors.text, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style:
                    TextStyle(color: colors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            StatusBadge(
              label: report.payrollStatus.label,
              kind: report.payrollStatus.colorKind,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}
