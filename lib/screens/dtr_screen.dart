import 'package:aris_mobile/models/status.dart';
import 'package:flutter/material.dart';

import '../models/dtr_entry.dart';
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
    // of what the search/filter is currently narrowing the table to.
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
      color: colors.bgPrimary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'DTR — ${MockDataService.currentPayrollPeriod}',
            style: TextStyle(
              color: colors.text,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _searchField(
            colors,
            controller: _searchController,
            hint: 'Search by date (e.g. Aug 17)',
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            onClear: () => setState(() => _query = ''),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
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
          const SizedBox(height: 12),
          SectionCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: entries.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No DTR entries match your search or filter.',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  )
                : Table(
                    columnWidths: const {
                      0: FlexColumnWidth(1.3),
                      1: FlexColumnWidth(1),
                      2: FlexColumnWidth(1),
                      3: FlexColumnWidth(1),
                    },
                    children: [
                      _headerRow(colors),
                      for (final e in entries) _dataRow(colors, e),
                    ],
                  ),
          ),
          SectionCard(
            title: 'Attendance Summary',
            child: Column(
              children: [
                _summaryRow(colors, 'Present', present),
                _summaryRow(colors, 'Late', late),
                _summaryRow(colors, 'Absent', absent),
                _summaryRow(colors, 'Missing punches', missing),
              ],
            ),
          ),
          SectionCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'DTR Status',
                  style: TextStyle(
                    color: colors.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                StatusBadge(
                  label: overallStage.label,
                  kind: overallStage.colorKind,
                ),
              ],
            ),
          ),
          Text(
            'Records are sourced from biometrics and cannot be edited '
            'directly. Tap an entry to report a discrepancy.',
            style: TextStyle(color: colors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _searchField(
    AppColors colors, {
    required TextEditingController controller,
    required String hint,
    required ValueChanged<String> onChanged,
    required VoidCallback onClear,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: TextStyle(color: colors.text, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: colors.textSecondary, fontSize: 13),
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
        fillColor: colors.bgSecondary,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.accent),
        ),
      ),
    );
  }

  Widget _filterChip(
    AppColors colors, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      backgroundColor: colors.bgSecondary,
      selectedColor: colors.accent.withOpacity(0.15),
      labelStyle: TextStyle(
        color: selected ? colors.accent : colors.textSecondary,
        fontSize: 12,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
      side: BorderSide(color: selected ? colors.accent : colors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );
  }

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

  TableRow _headerRow(AppColors colors) {
    final style = TextStyle(
      color: colors.textSecondary,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    );
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: Text('Date', style: style),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Text('Time In', style: style),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Text('Time Out', style: style),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Text('Status', style: style),
        ),
      ],
    );
  }

  TableRow _dataRow(AppColors colors, DtrEntry e) {
    final style = TextStyle(color: colors.text, fontSize: 13);
    late final String icon;
    late final Color color;
    switch (e.status) {
      case DtrDayStatus.present:
        icon = '✓';
        color = colors.success;
        break;
      case DtrDayStatus.late:
      case DtrDayStatus.missing:
        icon = '⚠';
        color = colors.warning;
        break;
      case DtrDayStatus.absent:
        icon = '✕';
        color = colors.error;
        break;
    }
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: Text(_shortDate(e.date), style: style),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Text(e.timeIn ?? '—', style: style),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Text(e.timeOut ?? '—', style: style),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Text(
            icon,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(AppColors colors, String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: colors.text, fontSize: 13)),
          Text(
            '$value',
            style: TextStyle(color: colors.text, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _shortDate(DateTime d) {
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
    return '${months[d.month - 1]} ${d.day}';
  }
}
