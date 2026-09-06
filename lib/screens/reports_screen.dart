import 'package:flutter/material.dart';

import '../models/status.dart';
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
      color: colors.bgPrimary,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Reports',
              style: TextStyle(
                color: colors.text,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _searchField(
              colors,
              controller: _searchController,
              hint: 'Search by period or professor',
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              onClear: () => setState(() => _query = ''),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
          const SizedBox(height: 4),
          Expanded(
            child: reports.isEmpty
                ? Center(
                    child: Text(
                      'No reports match your search or filter.',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: reports.length,
                    itemBuilder: (context, i) {
                      final report = reports[i];
                      final isFocused = report.id == widget.focusedReportId;
                      return InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ReportDetailScreen(report: report),
                          ),
                        ),
                        child: SectionCard(
                          padding: const EdgeInsets.all(14),
                          child: Container(
                            decoration: isFocused
                                ? BoxDecoration(
                                    border: Border.all(
                                      color: colors.accent,
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  )
                                : null,
                            padding: isFocused
                                ? const EdgeInsets.all(8)
                                : EdgeInsets.zero,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                          'Updated ${_relative(report.updatedAt)}',
                                          style: TextStyle(
                                            color: colors.textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    StatusBadge(
                                      label: report.stage.label,
                                      kind: report.stage.colorKind,
                                    ),
                                  ],
                                ),
                                if (report.stage == PipelineStage.rejected &&
                                    report.rejectionRemarks != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    report.rejectionRemarks!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: colors.error,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
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

  String _relative(DateTime date) {
    final diff = DateTime.now().difference(date).inDays;
    if (diff <= 0) return 'today';
    if (diff == 1) return 'yesterday';
    return '$diff days ago';
  }
}
