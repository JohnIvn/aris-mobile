import 'package:flutter/material.dart';

import '../models/report_item.dart';
import '../models/status.dart';
import '../theme/app_colors.dart';
import '../theme/theme_scope.dart';
import '../widgets/section_card.dart';
import '../widgets/status_badge.dart';

class ReportDetailScreen extends StatelessWidget {
  final ReportItem report;

  const ReportDetailScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final colors = ThemeScope.colorsOf(context);

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      appBar: AppBar(
        backgroundColor: colors.bgPrimary,
        foregroundColor: colors.text,
        elevation: 0,
        title: Text(report.periodLabel),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Updated ${_formatDate(report.updatedAt)}',
                style: TextStyle(color: colors.textSecondary, fontSize: 12),
              ),
              StatusBadge(label: report.stage.label, kind: report.stage.colorKind),
            ],
          ),
          const SizedBox(height: 12),
          if (report.stage == PipelineStage.rejected &&
              report.rejectionRemarks != null)
            _remarksCard(colors, report.rejectionRemarks!),
          SectionCard(
            title: 'Tally',
            child: Row(
              children: [
                Expanded(
                  child: _tallyStat(
                    colors,
                    label: 'DTR Time',
                    value: '${report.dtrTotalHours.toStringAsFixed(1)} hrs',
                  ),
                ),
                Container(width: 1, height: 40, color: colors.border),
                Expanded(
                  child: _tallyStat(
                    colors,
                    label: 'ARs Logged',
                    value: '${report.arTaskTally}',
                  ),
                ),
              ],
            ),
          ),
          SectionCard(
            title: 'Payroll',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Status',
                      style: TextStyle(color: colors.text, fontSize: 13),
                    ),
                    StatusBadge(
                      label: report.payrollStatus.label,
                      kind: report.payrollStatus.colorKind,
                    ),
                  ],
                ),
                if (report.payrollAvailableAt != null) ...[
                  const SizedBox(height: 8),
                  _detailRow(colors, 'Available Since',
                      _formatDate(report.payrollAvailableAt!)),
                ],
                if (report.payrollReceivedAt != null) ...[
                  const SizedBox(height: 4),
                  _detailRow(colors, 'Received On',
                      _formatDate(report.payrollReceivedAt!)),
                ],
                if (report.payrollStatus == PayrollStatus.notAvailable) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Payroll unlocks once Department, HR, and Accounting '
                        'have all verified this period\'s AR & DTR.',
                    style:
                    TextStyle(color: colors.textSecondary, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          SectionCard(
            title: 'Report Details',
            child: Column(
              children: [
                _detailRow(colors, 'Professor Name', report.professorName),
                _detailRow(colors, 'Professor ID', report.professorId),
                _detailRow(colors, 'Department', report.department),
                _detailRow(colors, 'Position', report.position),
                _detailRow(colors, 'Date of Shift', _formatDate(report.shiftDate)),
              ],
            ),
          ),
          SectionCard(
            title: 'Accomplishment Report',
            child: Text(
              report.reportNarrative,
              style: TextStyle(color: colors.text, fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _remarksCard(AppColors colors, String remarks) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: colors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rejection Remarks',
                  style: TextStyle(
                      color: colors.error, fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  remarks,
                  style: TextStyle(color: colors.text, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tallyStat(AppColors colors, {required String label, required String value}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(color: colors.text, fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
      ],
    );
  }

  Widget _detailRow(AppColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(color: colors.text, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
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
