import 'package:flutter/material.dart';

import '../models/status.dart';
import '../services/mock_data_service.dart';
import '../theme/theme_scope.dart';
import '../widgets/section_card.dart';
import '../widgets/status_badge.dart';
import 'report_detail_screen.dart';

class ReportsScreen extends StatelessWidget {
  final String? focusedReportId;

  const ReportsScreen({super.key, this.focusedReportId});

  @override
  Widget build(BuildContext context) {
    final colors = ThemeScope.colorsOf(context);
    final reports = MockDataService().getReports();

    return Container(
      color: colors.bgPrimary,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Reports',
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: reports.length,
              itemBuilder: (context, i) {
                final report = reports[i];
                final isFocused = report.id == focusedReportId;
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
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

  String _relative(DateTime date) {
    final diff = DateTime.now().difference(date).inDays;
    if (diff <= 0) return 'today';
    if (diff == 1) return 'yesterday';
    return '$diff days ago';
  }
}
