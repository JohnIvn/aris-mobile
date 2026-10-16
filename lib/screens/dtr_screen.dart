import 'package:flutter/material.dart';

import '../models/dtr_entry.dart';
import '../models/status.dart';
import '../services/mock_data_service.dart';
import '../theme/app_colors.dart';
import '../theme/theme_scope.dart';
import '../widgets/section_card.dart';
import '../widgets/status_badge.dart';

class DtrScreen extends StatefulWidget {
  const DtrScreen({super.key});

  @override
  State<DtrScreen> createState() => _DtrScreenState();
}

class _DtrScreenState extends State<DtrScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  DtrDayStatus? _filterStatus; // null = All

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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeScope.colorsOf(context);
    final data = MockDataService();
    final allEntries = data.getDtrEntries();
    final overallStage = data.getDtrOverallStage();

    // Attendance summary always reflects the full period, regardless
    // of what the search/filter is currently narrowing the list to.
    final present = allEntries
        .where((e) => e.status == DtrDayStatus.present)
        .length;
    final late = allEntries.where((e) => e.status == DtrDayStatus.late).length;
    final absent = allEntries
        .where((e) => e.status == DtrDayStatus.absent)
        .length;
    final missing = allEntries
        .where((e) => e.status == DtrDayStatus.missing)
        .length;

    final entries = allEntries.where((e) {
      final matchesQuery =
          _query.isEmpty || _shortDate(e.date).toLowerCase().contains(_query);
      final matchesFilter = _filterStatus == null || e.status == _filterStatus;
      return matchesQuery && matchesFilter;
    }).toList();

    return Container(
      color: colors.canvas,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          Text(
            'DTR',
            style: TextStyle(
              color: colors.text,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            MockDataService.currentPayrollPeriod,
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          _statusCard(colors, overallStage),
          _summaryCard(
            colors,
            total: allEntries.length,
            present: present,
            late: late,
            absent: absent,
            missing: missing,
          ),
          _searchField(
            colors,
            controller: _searchController,
            hint: 'Search by date (e.g. Aug 17)',
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
                for (final status in DtrDayStatus.values) ...[
                  _filterChip(
                    colors,
                    label: _statusLabel(status),
                    selected: _filterStatus == status,
                    onTap: () => setState(() => _filterStatus = status),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Daily Records',
            child: entries.isEmpty
                ? Text(
                    'No DTR entries match your search or filter.',
                    style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  )
                : Column(
                    children: [
                      for (var i = 0; i < entries.length; i++) ...[
                        if (i > 0) const SizedBox(height: 8),
                        _entryRow(colors, entries[i]),
                      ],
                    ],
                  ),
          ),
          Text(
            'Records are sourced from biometrics and cannot be edited '
            'directly. Tap an entry to report a discrepancy.',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ---- Cards ------------------------------------------------------------

  Widget _statusCard(AppColors colors, PipelineStage stage) {
    final current = _steps.indexOf(stage);
    final fill = _kindColor(colors, stage.colorKind);

    return SectionCard(
      title: 'DTR Status',
      action: StatusBadge(label: stage.label, kind: stage.colorKind),
      child: current >= 0
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
              ],
            )
          : Text(
              'Resubmit your corrected AR & DTR.',
              style: TextStyle(color: colors.textSecondary, fontSize: 13.5),
            ),
    );
  }

  Widget _summaryCard(
    AppColors colors, {
    required int total,
    required int present,
    required int late,
    required int absent,
    required int missing,
  }) {
    final segments = <(int, Color)>[
      (present, colors.success),
      (late, colors.warning),
      (missing, colors.warning),
      (absent, colors.error),
    ].where((s) => s.$1 > 0).toList();

    return SectionCard(
      title: 'Attendance Summary',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _summaryStat(
                  colors,
                  'Present',
                  present,
                  colors.success,
                ),
              ),
              Expanded(
                child: _summaryStat(colors, 'Late', late, colors.warning),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _summaryStat(colors, 'Absent', absent, colors.error),
              ),
              Expanded(
                child: _summaryStat(
                  colors,
                  'Missing punches',
                  missing,
                  colors.warning,
                ),
              ),
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: 18),
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

  Widget _summaryStat(AppColors colors, String label, int value, Color dot) {
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
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ---- Daily record rows -----------------------------------------------

  Widget _entryRow(AppColors colors, DtrEntry e) {
    final kind = _kindFor(e.status);
    final accent = _kindColor(colors, kind);
    final isPresent = e.status == DtrDayStatus.present;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPresent ? null : accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPresent
              ? colors.border.withValues(alpha: 0.5)
              : accent.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: colors.canvas,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  _month(e.date).toUpperCase(),
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  '${e.date.day}',
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: _timeColumn(colors, 'Time in', e.timeIn)),
          Expanded(child: _timeColumn(colors, 'Time out', e.timeOut)),
          const SizedBox(width: 8),
          Flexible(
            child: StatusBadge(label: _statusLabel(e.status), kind: kind),
          ),
        ],
      ),
    );
  }

  Widget _timeColumn(AppColors colors, String label, String? value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: colors.textSecondary, fontSize: 11.5),
        ),
        const SizedBox(height: 2),
        Text(
          value ?? '—',
          style: TextStyle(
            color: value == null ? colors.textSecondary : colors.text,
            fontSize: 14,
            fontWeight: value == null ? FontWeight.w400 : FontWeight.w600,
          ),
        ),
      ],
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

  // ---- Helpers ----------------------------------------------------------

  String _statusLabel(DtrDayStatus status) {
    switch (status) {
      case DtrDayStatus.present:
        return 'Present';
      case DtrDayStatus.late:
        return 'Late';
      case DtrDayStatus.missing:
        return 'Missing';
      case DtrDayStatus.absent:
        return 'Absent';
    }
  }

  /// Same colors the old table icons used: present = success,
  /// late/missing = warning, absent = error.
  StatusColorKind _kindFor(DtrDayStatus status) {
    switch (status) {
      case DtrDayStatus.present:
        return StatusColorKind.success;
      case DtrDayStatus.late:
      case DtrDayStatus.missing:
        return StatusColorKind.warning;
      case DtrDayStatus.absent:
        return StatusColorKind.error;
    }
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

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _month(DateTime d) => _months[d.month - 1];

  String _shortDate(DateTime d) => '${_month(d)} ${d.day}';
}