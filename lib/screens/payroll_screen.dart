import 'package:flutter/material.dart';

import '../models/report_item.dart';
import '../models/status.dart';
import '../services/mock_data_service.dart';
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
  final _searchController = TextEditingController();
  String _query = '';
  PayrollStatus? _filterStatus; // null = All

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeScope.colorsOf(context);
    final allReports = MockDataService().getReports();

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
      color: colors.bgPrimary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Payroll',
            style: TextStyle(
              color: colors.text,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Unlocks once Department, HR, and Accounting have all '
            'verified a period\'s AR & DTR.',
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Overview',
            child: Row(
              children: [
                Expanded(
                  child: _overviewStat(
                    colors,
                    'Available',
                    available,
                    colors.info,
                  ),
                ),
                Container(width: 1, height: 40, color: colors.border),
                Expanded(
                  child: _overviewStat(
                    colors,
                    'Received',
                    received,
                    colors.success,
                  ),
                ),
                Container(width: 1, height: 40, color: colors.border),
                Expanded(
                  child: _overviewStat(
                    colors,
                    'Pending',
                    pending,
                    colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _searchField(
            colors,
            controller: _searchController,
            hint: 'Search by period',
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
          const SizedBox(height: 12),
          if (reports.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No payroll records match your search or filter.',
                  style: TextStyle(color: colors.textSecondary, fontSize: 13),
                ),
              ),
            )
          else
            for (final report in reports) _payrollTile(context, colors, report),
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

  Widget _overviewStat(
    AppColors colors,
    String label,
    int value,
    Color valueColor,
  ) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            color: valueColor,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(color: colors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  Widget _payrollTile(
    BuildContext context,
    AppColors colors,
    ReportItem report,
  ) {
    late final String subtitle;
    if (report.payrollStatus == PayrollStatus.received &&
        report.payrollReceivedAt != null) {
      subtitle = 'Received ${_formatDate(report.payrollReceivedAt!)}';
    } else if (report.payrollStatus == PayrollStatus.available &&
        report.payrollAvailableAt != null) {
      subtitle = 'Available since ${_formatDate(report.payrollAvailableAt!)}';
    } else {
      subtitle = 'Awaiting full AR & DTR verification';
    }

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ReportDetailScreen(report: report)),
      ),
      child: SectionCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.periodLabel,
                    style: TextStyle(
                      color: colors.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            StatusBadge(
              label: report.payrollStatus.label,
              kind: report.payrollStatus.colorKind,
            ),
          ],
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
