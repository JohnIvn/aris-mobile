import 'package:flutter/material.dart';

import '../models/dtr_entry.dart';
import '../models/status.dart';
import '../services/dtr_service.dart';
import '../services/meet_service.dart';
import '../theme/app_colors.dart';
import '../theme/theme_scope.dart';
import '../widgets/section_card.dart';
import '../widgets/status_badge.dart';
import 'meet_list_screen.dart';

class RecordsScreen extends StatefulWidget {
  final bool embedded;

  const RecordsScreen({super.key, this.embedded = false});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  final _dtrService = DtrService();
  final _searchController = TextEditingController();

  String _query = '';
  DtrDayStatus? _filterStatus; // null = All

  List<String> _availableMonths = [];
  String _selectedMonth = '';
  List<DtrEntry> _entries = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _currentMonth() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
  }

  String _currentPeriod() {
    final now = DateTime.now();
    final half = now.day <= 15 ? 'I' : 'II';
    return '${_currentMonth()}-$half';
  }

  /// Discovers available months from /biometrics/transactions, exactly like aris-app.
  Future<void> _initData() async {
    final current = _currentMonth();
    final currentPeriod = _currentPeriod();
    setState(() {
      _selectedMonth = currentPeriod;
      _loading = true;
      _error = null;
    });

    try {
      final months = await _dtrService.fetchAvailableMonths();
      final monthSet = Set<String>.from(months);
      monthSet.add(current);

      // Also gather any months represented by Google Meet records
      final meetSvc = MeetService();
      if (meetSvc.items.isEmpty && !meetSvc.loading) {
        try {
          await meetSvc.load();
        } catch (_) {}
      }
      for (final m in meetSvc.items) {
        final ym = _extractYmFromDate(m.date);
        if (ym != null) monthSet.add(ym);
      }

      final periodSet = <String>{'$current-I', '$current-II'};
      for (final ym in monthSet) {
        periodSet.add('$ym-I');
        periodSet.add('$ym-II');
      }

      final sortedPeriods = periodSet.toList()..sort((a, b) => b.compareTo(a));

      final activePeriod = sortedPeriods.contains(currentPeriod)
          ? currentPeriod
          : sortedPeriods.first;

      if (!mounted) return;
      setState(() {
        _availableMonths = sortedPeriods;
        _selectedMonth = activePeriod;
      });

      await _fetchPunchesForMonth(activePeriod);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _availableMonths = ['$current-I', '$current-II'];
        _selectedMonth = currentPeriod;
      });
      await _fetchPunchesForMonth(currentPeriod);
    }
  }

  String? _extractYmFromDate(String dateStr) {
    if (dateStr.isEmpty) return null;
    final dt = DateTime.tryParse(dateStr);
    if (dt != null) {
      return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}';
    }
    const monthNames = [
      'january',
      'february',
      'march',
      'april',
      'may',
      'june',
      'july',
      'august',
      'september',
      'october',
      'november',
      'december',
    ];
    final lower = dateStr.toLowerCase();
    for (var i = 0; i < monthNames.length; i++) {
      if (lower.contains(monthNames[i])) {
        final match = RegExp(r'\b(20\d\d)\b').firstMatch(dateStr);
        final year = match?.group(1) ?? '${DateTime.now().year}';
        final month = (i + 1).toString().padLeft(2, '0');
        return '$year-$month';
      }
    }
    return null;
  }

  /// Fetches DTR records for the given YYYY-MM from /biometrics/transactions.
  Future<void> _fetchPunchesForMonth(String monthStr) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final parts = monthStr.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final half = parts.length > 2 ? parts[2] : 'I';
      final lastDay = half == 'I' ? 15 : DateTime(year, month + 1, 0).day;

      final startDate =
          '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${half == 'I' ? '01' : '16'}';
      final endDate =
          '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}';

      final result = await _dtrService.fetchEntries(
        startDate: startDate,
        endDate: endDate,
      );

      if (!mounted) return;
      setState(() {
        _entries = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeScope.colorsOf(context);

    return DefaultTabController(
      length: 2,
      child: Container(
        color: colors.canvas,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!widget.embedded)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Records',
                      style: TextStyle(
                        color: colors.text,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (_availableMonths.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _periodSelector(colors),
                    ],
                  ],
                ),
              )
            else if (_availableMonths.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
                child: Row(
                  children: [
                    Text(
                      'Period:',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _periodSelector(colors),
                  ],
                ),
              ),
            TabBar(
              labelColor: colors.accentActive,
              unselectedLabelColor: colors.textSecondary,
              indicatorColor: colors.accentActive,
              tabs: const [
                Tab(text: 'DTR'),
                Tab(text: 'Meet'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _dtrTab(context),
                  MeetRecordsView(selectedMonth: _selectedMonth),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _periodSelector(AppColors colors) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: _selectedMonth.isNotEmpty ? _selectedMonth : null,
        isDense: true,
        icon: Icon(Icons.keyboard_arrow_down, color: colors.accentActive),
        style: TextStyle(
          color: colors.accentActive,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        dropdownColor: colors.surface,
        items: [
          for (final m in _availableMonths)
            DropdownMenuItem<String>(value: m, child: Text(_monthLabel(m))),
        ],
        onChanged: (val) {
          if (val == null || val == _selectedMonth) return;
          setState(() {
            _selectedMonth = val;
            _query = '';
            _filterStatus = null;
            _searchController.clear();
          });
          _fetchPunchesForMonth(val);
        },
      ),
    );
  }

  Widget _dtrTab(BuildContext context) {
    final colors = ThemeScope.colorsOf(context);

    if (_loading && _entries.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null && _entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          children: [
            Text(
              'Could not load DTR records.\n$_error',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.error, fontSize: 13),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => _fetchPunchesForMonth(_selectedMonth),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final present = _entries
        .where((e) => e.status == DtrDayStatus.present)
        .length;
    final late = _entries.where((e) => e.status == DtrDayStatus.late).length;
    final absent = _entries
        .where((e) => e.status == DtrDayStatus.absent)
        .length;
    final missing = _entries
        .where((e) => e.status == DtrDayStatus.missing)
        .length;

    final filtered = _entries.where((e) {
      final matchesQuery =
          _query.isEmpty || _shortDate(e.date).toLowerCase().contains(_query);
      final matchesFilter = _filterStatus == null || e.status == _filterStatus;
      return matchesQuery && matchesFilter;
    }).toList();

    return RefreshIndicator(
      onRefresh: () => _fetchPunchesForMonth(_selectedMonth),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          _summaryCard(
            colors,
            total: _entries.length,
            present: present,
            late: late,
            absent: absent,
            missing: missing,
          ),
          _searchField(
            colors,
            controller: _searchController,
            hint: 'Search by date (e.g. Nov 2)',
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
            child: filtered.isEmpty
                ? Text(
                    _entries.isEmpty
                        ? 'No DTR entries for this period yet.'
                        : 'No DTR entries match your search or filter.',
                    style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  )
                : Column(
                    children: [
                      for (var i = 0; i < filtered.length; i++) ...[
                        if (i > 0) const SizedBox(height: 8),
                        _entryRow(colors, filtered[i]),
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
                child: _summaryStat(colors, 'Present', present, colors.success),
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

  String _month(DateTime d) => _months[d.month - 1];

  String _shortDate(DateTime d) => '${_month(d)} ${d.day}';

  String _monthLabel(String ym) {
    final parts = ym.split('-');
    if (parts.length < 2) return ym;
    final year = int.tryParse(parts[0]) ?? DateTime.now().year;
    final month = int.tryParse(parts[1]) ?? DateTime.now().month;
    const fullMonths = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final half = parts.length > 2 ? ' ${parts[2]}' : '';
    return '${fullMonths[month - 1]} $year$half';
  }
}
