import 'package:flutter/material.dart';

import '../models/report_item.dart';
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
    final next = _nextAction(latest);

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
                // AR and DTR are submitted and verified together, so
                // they share a single stage instead of two rows.
                _statusRow(
                  colors,
                  'AR & DTR',
                  latest.stage.label,
                  latest.stage.colorKind,
                ),
                const SizedBox(height: 8),
                _statusRow(
                  colors,
                  'Payroll',
                  latest.payrollStatus.label,
                  latest.payrollStatus.colorKind,
                ),
              ],
            ),
          ),
          SectionCard(
            title: 'Next Action',
            child: Row(
              children: [
                Icon(next.icon, color: next.color(colors), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    next.text,
                    style: TextStyle(color: colors.text, fontSize: 14),
                  ),
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

  Widget _statusRow(
      AppColors colors,
      String label,
      String value,
      StatusColorKind kind,
      ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: colors.text, fontSize: 14),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        const SizedBox(width: 8),
        StatusBadge(label: value, kind: kind),
      ],
    );
  }

  /// What to show in "Next Action", driven by the combined AR+DTR
  /// stage and — once that's completed — the payroll status.
  _NextAction _nextAction(ReportItem latest) {
    switch (latest.stage) {
      case PipelineStage.rejected:
        return _NextAction(
          Icons.error_outline,
          'Resubmit corrected AR & DTR',
              (c) => c.error,
        );
      case PipelineStage.draft:
        return _NextAction(
          Icons.edit_outlined,
          'Finish and submit your AR & DTR',
              (c) => c.warning,
        );
      case PipelineStage.submitted:
        return _NextAction(
          Icons.hourglass_empty,
          'Submitted — awaiting Department Secretary verification',
              (c) => c.warning,
        );
      case PipelineStage.department:
        return _NextAction(
          Icons.hourglass_empty,
          'Awaiting Department Secretary verification',
              (c) => c.warning,
        );
      case PipelineStage.hr:
        return _NextAction(
          Icons.hourglass_empty,
          'Awaiting HR verification',
              (c) => c.warning,
        );
      case PipelineStage.accounting:
        return _NextAction(
          Icons.hourglass_empty,
          'Awaiting Accounting verification',
              (c) => c.warning,
        );
      case PipelineStage.completed:
        switch (latest.payrollStatus) {
          case PayrollStatus.available:
            return _NextAction(
              Icons.payments_outlined,
              'Payroll is available for release',
                  (c) => c.info,
            );
          case PayrollStatus.received:
            return _NextAction(
              Icons.check_circle_outline,
              'No action required',
                  (c) => c.accent,
            );
          case PayrollStatus.notAvailable:
            return _NextAction(
              Icons.hourglass_empty,
              'Fully verified — payroll is being processed',
                  (c) => c.warning,
            );
        }
    }
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

class _NextAction {
  final IconData icon;
  final String text;
  final Color Function(AppColors colors) color;

  const _NextAction(this.icon, this.text, this.color);
}
