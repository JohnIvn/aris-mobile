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

  /// Happy-path order of the pipeline. `rejected` is not a step.
  static const _steps = [
    PipelineStage.draft,
    PipelineStage.submitted,
    PipelineStage.department,
    PipelineStage.hr,
    PipelineStage.accounting,
    PipelineStage.completed,
  ];

  @override
  Widget build(BuildContext context) {
    final colors = ThemeScope.colorsOf(context);

    return Scaffold(
      backgroundColor: colors.canvas,
      appBar: AppBar(
        backgroundColor: colors.canvas,
        foregroundColor: colors.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Text(
          report.periodLabel,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          _progressCard(colors),
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
                Container(
                  width: 1,
                  height: 40,
                  color: colors.border.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 20),
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
                _divided(colors, [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Status',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 13.5,
                        ),
                      ),
                      Flexible(
                        child: StatusBadge(
                          label: report.payrollStatus.label,
                          kind: report.payrollStatus.colorKind,
                        ),
                      ),
                    ],
                  ),
                  if (report.payrollAvailableAt != null)
                    _detailRow(
                      colors,
                      'Available Since',
                      _formatDate(report.payrollAvailableAt!),
                    ),
                  if (report.payrollReceivedAt != null)
                    _detailRow(
                      colors,
                      'Received On',
                      _formatDate(report.payrollReceivedAt!),
                    ),
                ]),
                if (report.payrollStatus == PayrollStatus.notAvailable) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Payroll unlocks once Department, HR, and Accounting '
                    'have all verified this period\'s AR & DTR.',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SectionCard(
            title: 'Report Details',
            child: _divided(colors, [
              _detailRow(colors, 'Professor Name', report.professorName),
              _detailRow(colors, 'Professor ID', report.professorId),
              _detailRow(colors, 'Department', report.department),
              _detailRow(colors, 'Position', report.position),
              _detailRow(colors, 'Date of Shift', _formatDate(report.shiftDate)),
            ]),
          ),
          SectionCard(
            title: 'Accomplishment Report',
            child: Text(
              report.reportNarrative,
              style: TextStyle(color: colors.text, fontSize: 14, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Color _kindColor(AppColors c, StatusColorKind kind) {
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

  /// Stage badge, a segmented bar of the pipeline (not shown for
  /// rejected reports, which have no position in it), and the date.
  Widget _progressCard(AppColors colors) {
    final current = _steps.indexOf(report.stage);
    final fill = _kindColor(colors, report.stage.colorKind);

    return SectionCard(
      title: 'Progress',
      action: StatusBadge(
        label: report.stage.label,
        kind: report.stage.colorKind,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (current >= 0) ...[
            Row(
              children: [
                for (var i = 0; i < _steps.length; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: i <= current
                            ? fill
                            : colors.border.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Step ${current + 1} of ${_steps.length}',
              style: TextStyle(
                color: colors.text,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
          ],
          Text(
            'Updated ${_formatDate(report.updatedAt)}',
            style: TextStyle(color: colors.textSecondary, fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  Widget _remarksCard(AppColors colors, String remarks) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.error.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.error_outline, color: colors.error, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rejection Remarks',
                  style: TextStyle(
                    color: colors.error,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  remarks,
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 13.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tallyStat(
    AppColors colors, {
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: colors.textSecondary, fontSize: 12.5),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: colors.text,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  /// Stacks [rows] with a hairline divider between each.
  Widget _divided(AppColors colors, List<Widget> rows) {
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
      children.add(rows[i]);
    }
    return Column(children: children);
  }

  Widget _detailRow(AppColors colors, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: colors.textSecondary, fontSize: 13.5),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: colors.text,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
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