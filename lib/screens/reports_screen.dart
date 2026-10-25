import 'package:flutter/material.dart';

import '../models/report_item.dart';
import '../models/status.dart';
import '../services/ar_service.dart';
import '../stores/report_stores.dart';
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
  final _store = ReportsStore();
  final _scroll = ScrollController();
  final _searchController = TextEditingController();
  String _query = '';
  int? _filterStage; // null = All, else backend stage 1-4

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    if (_store.reports.isEmpty) _store.load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.extentAfter < 300) _store.loadMore();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) => _content(context),
    );
  }

  Widget _content(BuildContext context) {
    final colors = ThemeScope.colorsOf(context);
    final allReports = _store.reports;

    final reports = allReports.where((r) {
      final matchesQuery =
          _query.isEmpty ||
          r.periodLabel.toLowerCase().contains(_query) ||
          r.professorName.toLowerCase().contains(_query) ||
          r.professorId.toLowerCase().contains(_query);
      final matchesFilter =
          _filterStage == null || _store.stageOf(r) == _filterStage;
      return matchesQuery && matchesFilter;
    }).toList();

    return Container(
      color: colors.canvas,
      child: RefreshIndicator(
        onRefresh: _store.load,
        child: CustomScrollView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
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
                    for (var n = 1; n <= 4; n++) ...[
                      _filterChip(
                        colors,
                        label: ReportsStore.stageLabels[n - 1],
                        selected: _filterStage == n,
                        onTap: () => setState(() => _filterStage = n),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            if (reports.isEmpty)
              SliverToBoxAdapter(child: _emptyState(colors, allReports.isEmpty))
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _reportCard(context, colors, reports[i]),
                    childCount: reports.length,
                  ),
                ),
              ),
            SliverToBoxAdapter(child: _footer(colors, allReports.isNotEmpty)),
          ],
        ),
      ),
    );
  }

  /// Spinner while a page loads, retry if a page failed.
  Widget _footer(AppColors colors, bool hasData) {
    if (_store.loadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }
    if (hasData && _store.error != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          children: [
            Text(
              _store.error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.error, fontSize: 12.5),
            ),
            TextButton(
              onPressed: _store.loadMore,
              child: const Text('Try again'),
            ),
          ],
        ),
      );
    }
    return const SizedBox(height: 28);
  }

  Widget _emptyState(AppColors colors, bool noData) {
    if (noData && _store.loading) {
      return const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (noData && _store.error != null) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Text(
              'Could not load reports.\n${_store.error}',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.error, fontSize: 13),
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _store.load, child: const Text('Retry')),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Text(
          noData
              ? 'No reports yet.'
              : 'No reports match your search or filter.',
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.textSecondary, fontSize: 13),
        ),
      ),
    );
  }

  /// Summary of all loaded reports by backend stage
  /// (pending, department, HR, accounting).
  Widget _summaryCard(AppColors colors, List<ReportItem> all) {
    final total = all.length;
    final counts = List<int>.filled(4, 0);
    for (final r in all) {
      counts[_store.stageOf(r) - 1]++;
    }
    String pct(int n) => '${(n * 100 / total).round()}%';

    final dots = <Color>[
      colors.textSecondary,
      colors.warning,
      colors.info,
      colors.success,
    ];
    final segments = <(int, Color)>[
      for (var i = 0; i < 4; i++)
        if (counts[i] > 0) (counts[i], dots[i]),
    ];

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
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < 4; i++)
                Expanded(
                  child: _summaryStat(
                    colors,
                    ReportsStore.stageLabels[i],
                    counts[i],
                    pct(counts[i]),
                    dots[i],
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
    final stage = _store.stageOf(report);

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
                        label: ReportsStore
                            .stageLabels[_store.stageOf(report) - 1],
                        kind: _store.stageOf(report) == 4
                            ? StatusColorKind.success
                            : StatusColorKind.info,
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
                        _hours(report.dtrTally),
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
                      'Progress',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Stage $stage of 4 · ${ReportsStore.stageLabels[stage - 1]}',
                      style: TextStyle(
                        color: colors.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (var n = 1; n <= 4; n++) ...[
                      if (n > 1) const SizedBox(width: 4),
                      Expanded(
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: n <= stage
                                ? (stage == 4
                                      ? colors.success
                                      : colors.accentActive)
                                : colors.border.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
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
