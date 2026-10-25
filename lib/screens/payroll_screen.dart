import 'package:flutter/material.dart';

import '../models/report_item.dart';
import '../models/status.dart';
import '../stores/report_stores.dart';
import '../theme/app_colors.dart';
import '../theme/theme_scope.dart';
import '../widgets/section_card.dart';
import '../widgets/status_badge.dart';
import 'report_detail_screen.dart';

class PayrollScreen extends StatefulWidget {
  const PayrollScreen({super.key});

  @override
  State<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen> {
  final _store = ReportsStore();
  final _scroll = ScrollController();
  final _searchController = TextEditingController();
  String _query = '';
  PayrollStatus? _filterStatus; // null = All

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

    // Overview counts always reflect everything, regardless of the
    // current search/filter narrowing the list below.
    final available = allReports
        .where((r) => r.payrollStatus == PayrollStatus.available)
        .length;
    final received = allReports
        .where((r) => r.payrollStatus == PayrollStatus.received)
        .length;
    final pending = allReports
        .where((r) => r.payrollStatus == PayrollStatus.notAvailable)
        .length;

    final reports = allReports.where((r) {
      final matchesQuery =
          _query.isEmpty || r.periodLabel.toLowerCase().contains(_query);
      final matchesFilter =
          _filterStatus == null || r.payrollStatus == _filterStatus;
      return matchesQuery && matchesFilter;
    }).toList();

    return Container(
      color: colors.canvas,
      child: RefreshIndicator(
        onRefresh: _store.load,
        child: ListView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            Text(
              'Payroll',
              style: TextStyle(
                color: colors.text,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Unlocks once Department, HR, and Accounting have all '
              'verified a period\'s AR & DTR.',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            _overviewCard(
              colors,
              total: allReports.length,
              available: available,
              received: received,
              pending: pending,
            ),
            _searchField(
              colors,
              controller: _searchController,
              hint: 'Search by period',
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              onClear: () => setState(() => _query = ''),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _filterChip(
                    colors,
                    label: 'All',
                    selected: _filterStatus == null,
                    onTap: () => setState(() => _filterStatus = null),
                  ),
                  const SizedBox(width: 8),
                  for (final status in PayrollStatus.values) ...[
                    _filterChip(
                      colors,
                      label: status.label,
                      selected: _filterStatus == status,
                      onTap: () => setState(() => _filterStatus = status),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (reports.isEmpty)
              _emptyState(colors, allReports.isEmpty)
            else
              for (final report in reports)
                _payrollTile(context, colors, report),
            if (_store.loadingMore)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
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
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Text(
              'Could not load payroll.\n${_store.error}',
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
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          noData
              ? 'No payroll records yet.'
              : 'No payroll records match your search or filter.',
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.textSecondary, fontSize: 13),
        ),
      ),
    );
  }

  // ---- Overview ---------------------------------------------------------

  Color _pendingColor(AppColors colors) =>
      colors.textSecondary.withValues(alpha: 0.6);

  Widget _overviewCard(
    AppColors colors, {
    required int total,
    required int available,
    required int received,
    required int pending,
  }) {
    final segments = <(int, Color)>[
      (received, colors.success),
      (available, colors.info),
      (pending, _pendingColor(colors)),
    ].where((s) => s.$1 > 0).toList();

    return SectionCard(
      title: 'Overview',
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
                total == 1 ? 'pay period' : 'pay periods',
                style: TextStyle(color: colors.textSecondary, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _overviewStat(
                  colors,
                  'Available',
                  available,
                  colors.info,
                ),
              ),
              Expanded(
                child: _overviewStat(
                  colors,
                  'Received',
                  received,
                  colors.success,
                ),
              ),
              Expanded(
                child: _overviewStat(
                  colors,
                  'Pending',
                  pending,
                  _pendingColor(colors),
                ),
              ),
            ],
          ),
          if (total > 0) ...[
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
        ],
      ),
    );
  }

  Widget _overviewStat(AppColors colors, String label, int value, Color dot) {
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
        Text(
          '$value',
          style: TextStyle(
            color: colors.text,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ---- Payroll cards ----------------------------------------------------

  Color _statusColor(AppColors colors, PayrollStatus status) {
    switch (status) {
      case PayrollStatus.available:
        return colors.info;
      case PayrollStatus.received:
        return colors.success;
      case PayrollStatus.notAvailable:
        return colors.textSecondary;
    }
  }

  IconData _statusIcon(PayrollStatus status) {
    switch (status) {
      case PayrollStatus.available:
        return Icons.payments_outlined;
      case PayrollStatus.received:
        return Icons.check_circle_outline;
      case PayrollStatus.notAvailable:
        return Icons.hourglass_empty;
    }
  }

  String _subtitleFor(ReportItem report) {
    if (report.payrollStatus == PayrollStatus.received) {
      return report.payrollReceivedAt != null
          ? 'Received ${_formatDate(report.payrollReceivedAt!)}'
          : 'Received';
    } else if (report.payrollStatus == PayrollStatus.available) {
      return report.payrollAvailableAt != null
          ? 'Available since ${_formatDate(report.payrollAvailableAt!)}'
          : 'Payroll is ready for release';
    }
    return 'Awaiting full AR & DTR verification';
  }

  Widget _payrollTile(
    BuildContext context,
    AppColors colors,
    ReportItem report,
  ) {
    final accent = _statusColor(colors, report.payrollStatus);
    // Payroll that is ready for release is the one thing worth drawing
    // the eye to, so it gets a soft tint.
    final highlight = report.payrollStatus == PayrollStatus.available;

    return SectionCard(
      padding: EdgeInsets.zero,
      child: Material(
        color: highlight
            ? colors.info.withValues(alpha: 0.06)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ReportDetailScreen(report: report),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _statusIcon(report.payrollStatus),
                    color: accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              report.periodLabel,
                              style: TextStyle(
                                color: colors.text,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: StatusBadge(
                              label: report.payrollStatus.label,
                              kind: report.payrollStatus.colorKind,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _subtitleFor(report),
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 12.5,
                                height: 1.35,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: colors.textSecondary,
                            size: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---- Search + filters -------------------------------------------------

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
