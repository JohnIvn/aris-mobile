import 'package:flutter/material.dart';

import '../models/report_item.dart';
import '../models/status.dart';
import '../services/ar_service.dart';
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
    final s = ArService().summarize(report);

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
          _progressCard(colors, s),
          if (s.forResubmission + s.invalid + s.forwarded > 0)
            _attentionCard(colors, s),
          SectionCard(
            title: 'Tally',
            child: Row(
              children: [
                Expanded(
                  child: _tallyStat(
                    colors,
                    label: 'DTR Time (Biometrics)',
                    value: '${report.dtrTotalHours.toStringAsFixed(1)} hrs',
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: colors.border.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 20),
                Expanded(child: _arsButton(colors, s.total)),
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

  /// AR verification percentage across the ARs still in the batch, with a
  /// breakdown of every AR by state.
  Widget _progressCard(AppColors colors, ArSummary s) {
    return SectionCard(
      title: 'Progress',
      action: StatusBadge(
        label: '${s.percent}% verified',
        kind: s.percent == 100 ? StatusColorKind.success : StatusColorKind.info,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: s.percent / 100,
              minHeight: 8,
              backgroundColor: colors.border.withValues(alpha: 0.5),
              valueColor: AlwaysStoppedAnimation(
                s.percent == 100 ? colors.success : colors.accentActive,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${s.active} of ${s.total} ARs in this batch',
            style: TextStyle(
              color: colors.text,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _legend(colors, 'Approved', s.approved, colors.success),
              _legend(colors, 'In review', s.inReview, colors.info),
              _legend(
                colors,
                'For resubmission',
                s.forResubmission,
                colors.error,
              ),
              _legend(colors, 'Invalid', s.invalid, colors.error),
              _legend(colors, 'Forwarded', s.forwarded, colors.textSecondary),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Updated ${_formatDate(report.updatedAt)}',
            style: TextStyle(color: colors.textSecondary, fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  Widget _legend(AppColors colors, String label, int count, Color dot) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$count $label',
          style: TextStyle(color: colors.textSecondary, fontSize: 12.5),
        ),
      ],
    );
  }

  /// Replaces the old rejection-remarks card: surfaces ARs needing action.
  Widget _attentionCard(AppColors colors, ArSummary s) {
    final urgent = s.forResubmission + s.invalid > 0;
    final color = urgent ? colors.error : colors.textSecondary;
    final lines = [
      if (s.forResubmission > 0)
        '${s.forResubmission} AR${s.forResubmission == 1 ? '' : 's'} '
            'rejected, awaiting resubmission',
      if (s.invalid > 0) '${s.invalid} invalid (removed from this batch)',
      if (s.forwarded > 0)
        '${s.forwarded} missed the cutoff and moved to the next period',
    ];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.error_outline, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ARs Need Attention',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                for (final l in lines)
                  Text(
                    l,
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 13.5,
                      height: 1.45,
                    ),
                  ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _openArs,
                  child: Text(
                    'Review ARs',
                    style: TextStyle(
                      color: colors.accentActive,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ],
            ),
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
