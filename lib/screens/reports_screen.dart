import 'package:flutter/material.dart';

import '../models/report_item.dart';
import '../models/status.dart';
import '../services/ar_service.dart';
import '../services/mock_data_service.dart';
import '../theme/app_colors.dart';
import '../theme/theme_scope.dart';
import '../widgets/section_card.dart';
import '../widgets/status_badge.dart';
import 'report_detail_screen.dart';

class ReportsScreen extends StatefulWidget {
  final String? focusedReportId;

  const ReportsScreen({super.key, this.focusedReportId});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  PipelineStage? _filterStage; // null = All

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeScope.colorsOf(context);
    final allReports = MockDataService().getReports();

    final reports = allReports.where((r) {
      final matchesQuery =
          _query.isEmpty ||
          r.periodLabel.toLowerCase().contains(_query) ||
          r.professorName.toLowerCase().contains(_query) ||
          r.professorId.toLowerCase().contains(_query);
      final matchesFilter = _filterStage == null || r.stage == _filterStage;
      return matchesQuery && matchesFilter;
    }).toList();

    return Container(
      color: colors.canvas,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reports',
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (allReports.isNotEmpty) _summaryCard(colors, allReports),
                  _searchField(
                    colors,
                    controller: _searchController,
                    hint: 'Search by period or professor',
                    onChanged: (v) =>
                        setState(() => _query = v.trim().toLowerCase()),
                    onClear: () => setState(() => _query = ''),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _filterChip(
                    colors,
                    label: 'All',
                    selected: _filterStage == null,
                    onTap: () => setState(() => _filterStage = null),
                  ),
                  const SizedBox(width: 8),
                  for (final stage in PipelineStage.values) ...[
                    _filterChip(
                      colors,
                      label: stage.label,
                      selected: _filterStage == stage,
                      onTap: () => setState(() => _filterStage = stage),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          if (reports.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'No reports match your search or filter.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _reportCard(context, colors, reports[i]),
                  childCount: reports.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Summary of all reports (not just the filtered ones), based on the
  /// AR verification progress of each report.
  Widget _summaryCard(AppColors colors, List<ReportItem> all) {
    final total = all.length;
    final sums = all.map((r) => ArService().summarize(r)).toList();
    final verified = sums.where((s) => s.percent == 100).length;
    final needsAction = sums
        .where((s) => s.percent < 100 && s.needsAction)
        .length;
    final inVerification = total - verified - needsAction;
    final overall =
        (sums.fold<int>(0, (a, s) => a + s.percent) / total).round();
    String pct(int n) => '${(n * 100 / total).round()}%';

    final segments = <(int, Color)>[
      (verified, colors.success),
      (inVerification, colors.warning),
      (needsAction, colors.error),
    ].where((s) => s.$1 > 0).toList();

    return SectionCard(
      title: 'Report Summary',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$total',
                style: TextStyle(
                  color: colors.text,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                total == 1 ? 'report' : 'reports',
                style: TextStyle(color: colors.textSecondary, fontSize: 14),
              ),
              const Spacer(),
              Text(
                '$overall%',
                style: TextStyle(
                  color: colors.text,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'verified',
                style: TextStyle(color: colors.textSecondary, fontSize: 12.5),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _summaryStat(
                  colors,
                  'Verified',
                  verified,
                  pct(verified),
                  colors.success,
                ),
              ),
              Expanded(
                child: _summaryStat(
                  colors,
                  'In verification',
                  inVerification,
                  pct(inVerification),
                  colors.warning,
                ),
              ),
              Expanded(
                child: _summaryStat(
                  colors,
                  'Needs action',
                  needsAction,
                  pct(needsAction),
                  colors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  for (var i = 0; i < segments.length; i++) ...[
                    if (i > 0) const SizedBox(width: 2),
                    Expanded(
                      flex: segments[i].$1,
                      child: Container(color: segments[i].$2),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryStat(
    AppColors colors,
    String label,
    int count,
    String percent,
    Color dot,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colors.textSecondary, fontSize: 12.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '$count',
              style: TextStyle(
                color: colors.text,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              percent,
              style: TextStyle(color: colors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _reportCard(
    BuildContext context,
    AppColors colors,
    ReportItem report,
  ) {
    final isFocused = report.id == widget.focusedReportId;
    final s = ArService().summarize(report);
    final attention = s.forResubmission + s.invalid + s.forwarded;
    final attentionColor = (s.forResubmission + s.invalid) > 0
        ? colors.error
        : colors.textSecondary;

    return SectionCard(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ReportDetailScreen(report: report),
              ),
            );
            if (mounted) setState(() {});
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            foregroundDecoration: isFocused
                ? BoxDecoration(
                    border: Border.all(color: colors.accentActive, width: 1.5),
                    borderRadius: BorderRadius.circular(20),
                  )
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            report.periodLabel,
                            style: TextStyle(
                              color: colors.text,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Updated ${_relative(report.updatedAt)}',
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: StatusBadge(
                        label: report.stage.label,
                        kind: report.stage.colorKind,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _stat(
                        colors,
                        'DTR hours',
                        _hours(report.dtrTotalHours),
                      ),
                    ),
                    Expanded(child: _stat(colors, 'ARs', '${s.total}')),
                    Icon(Icons.chevron_right, color: colors.textSecondary),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Text(
                      'Verification',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${s.percent}%',
                      style: TextStyle(
                        color: colors.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: s.percent / 100,
                    minHeight: 6,
                    backgroundColor: colors.border.withValues(alpha: 0.5),
                    valueColor: AlwaysStoppedAnimation(
                      s.percent == 100 ? colors.success : colors.accentActive,
                    ),
                  ),
                ),
                if (attention > 0) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: attentionColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: attentionColor,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            [
                              if (s.forResubmission > 0)
                                '${s.forResubmission} for resubmission',
                              if (s.invalid > 0) '${s.invalid} invalid',
                              if (s.forwarded > 0)
                                '${s.forwarded} forwarded to next period',
                            ].join(' · '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: attentionColor,
                              fontSize: 12.5,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stat(AppColors colors, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: colors.textSecondary, fontSize: 12.5),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: colors.text,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  String _hours(double h) =>
      h == h.roundToDouble() ? h.toInt().toString() : h.toStringAsFixed(1);

  Widget _searchField(
    AppColors colors, {
    required TextEditingController controller,
    required String hint,
    required ValueChanged<String> onChanged,
    required VoidCallback onClear,
  }) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color),
    );
    final hairline = colors.border.withValues(alpha: 0.6);

    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: TextStyle(color: colors.text, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: colors.textSecondary, fontSize: 13.5),
        prefixIcon: Icon(Icons.search, color: colors.textSecondary, size: 20),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: Icon(Icons.close, color: colors.textSecondary, size: 18),
                onPressed: () {
                  controller.clear();
                  onClear();
                },
              ),
        filled: true,
        fillColor: colors.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 13,
          horizontal: 14,
        ),
        border: border(hairline),
        enabledBorder: border(hairline),
        focusedBorder: border(colors.accentActive),
      ),
    );
  }

  Widget _filterChip(
    AppColors colors, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: selected
                  ? colors.accent.withValues(alpha: 0.14)
                  : colors.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected
                    ? colors.accentActive.withValues(alpha: 0.5)
                    : colors.border.withValues(alpha: 0.6),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? colors.accentActive : colors.textSecondary,
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _relative(DateTime date) {
    final diff = DateTime.now().difference(date).inDays;
    if (diff <= 0) return 'today';
    if (diff == 1) return 'yesterday';
    return '$diff days ago';
  }
}
