import 'package:flutter/material.dart';

import '../models/report_item.dart';
import '../models/status.dart';
import '../services/ar_service.dart';
import '../stores/report_stores.dart';
import '../theme/app_colors.dart';
import '../theme/theme_scope.dart';
import '../widgets/section_card.dart';
import '../widgets/status_badge.dart';
import 'ar_list_screen.dart';

class ReportDetailScreen extends StatefulWidget {
  final ReportItem report;

  const ReportDetailScreen({super.key, required this.report});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  ReportItem get report => widget.report;

  Future<void> _openArs() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => ArListScreen(report: report)));
    if (mounted) setState(() {}); // AR states may have changed
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeScope.colorsOf(context);
    final arCount = ArService().forReport(report).length;
    final stage = ReportsStore().stageOf(report);

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
          _progressCard(colors, stage),
          SectionCard(
            title: 'Tally',
            child: Row(
              children: [
                Expanded(
                  child: _tallyStat(
                    colors,
                    label: 'DTR Time (Biometrics)',
                    value: '${report.dtrTally.toStringAsFixed(1)} hrs',
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: colors.border.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 20),
                Expanded(child: _arsButton(colors, arCount)),
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
              _detailRow(
                colors,
                'Date of Shift',
                _formatDate(report.shiftDate),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  /// Report progress through the four backend stages
  /// (pending, department, HR, accounting).
  Widget _progressCard(AppColors colors, int stage) {
    final done = stage == 4;
    final active = done ? colors.success : colors.accentActive;

    return SectionCard(
      title: 'Progress',
      action: StatusBadge(
        label: ReportsStore.stageLabels[stage - 1],
        kind: done ? StatusColorKind.success : StatusColorKind.info,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var n = 1; n <= 4; n++) ...[
                if (n > 1) const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: n <= stage
                              ? active
                              : colors.border.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ReportsStore.stageLabels[n - 1],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: n == stage
                              ? colors.text
                              : colors.textSecondary,
                          fontSize: 12,
                          fontWeight: n == stage
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Stage $stage of 4',
            style: TextStyle(
              color: colors.text,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Updated ${_formatDate(report.updatedAt)}',
            style: TextStyle(color: colors.textSecondary, fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  /// Clickable AR count that opens the AR list.
  Widget _arsButton(AppColors colors, int total) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _openArs,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ARs Logged',
              style: TextStyle(color: colors.textSecondary, fontSize: 12.5),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Flexible(
                  child: Text(
                    '$total ${total == 1 ? 'AR' : 'ARs'}',
                    style: TextStyle(
                      color: colors.accentActive,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: colors.accentActive),
              ],
            ),
          ],
        ),
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
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}
