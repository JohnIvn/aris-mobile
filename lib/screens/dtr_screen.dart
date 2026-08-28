import 'package:aris_mobile/models/status.dart';
import 'package:flutter/material.dart';

import '../models/dtr_entry.dart';
import '../services/mock_data_service.dart';
import '../theme/app_colors.dart';
import '../theme/theme_scope.dart';
import '../widgets/section_card.dart';
import '../widgets/status_badge.dart';

class DtrScreen extends StatelessWidget {
  const DtrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = ThemeScope.colorsOf(context);
    final data = MockDataService();
    final entries = data.getDtrEntries();
    final overallStage = data.getDtrOverallStage();

    final present =
        entries.where((e) => e.status == DtrDayStatus.present).length;
    final late = entries.where((e) => e.status == DtrDayStatus.late).length;
    final absent =
        entries.where((e) => e.status == DtrDayStatus.absent).length;
    final missing =
        entries.where((e) => e.status == DtrDayStatus.missing).length;

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
          SectionCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Table(
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    'DTR Status',
                    style: TextStyle(color: colors.text, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 8),
                StatusBadge(label: overallStage.label, kind: overallStage.colorKind),
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

  TableRow _headerRow(AppColors colors) {
    final style = TextStyle(
      color: colors.textSecondary,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    );
    return TableRow(children: [
      Padding(
          padding: const EdgeInsets.all(10), child: Text('Date', style: style)),
      Padding(
          padding: const EdgeInsets.all(10),
          child: Text('Time In', style: style)),
      Padding(
          padding: const EdgeInsets.all(10),
          child: Text('Time Out', style: style)),
      Padding(
          padding: const EdgeInsets.all(10),
          child: Text('Status', style: style)),
    ]);
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
    return TableRow(children: [
      Padding(
          padding: const EdgeInsets.all(10),
          child: Text(_shortDate(e.date), style: style)),
      Padding(
          padding: const EdgeInsets.all(10),
          child: Text(e.timeIn ?? '—', style: style)),
      Padding(
          padding: const EdgeInsets.all(10),
          child: Text(e.timeOut ?? '—', style: style)),
      Padding(
        padding: const EdgeInsets.all(10),
        child: Text(icon,
            style: TextStyle(color: color, fontWeight: FontWeight.w700)),
      ),
    ]);
  }

  Widget _summaryRow(AppColors colors, String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: colors.text, fontSize: 13)),
          Text('$value',
              style:
                  TextStyle(color: colors.text, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _shortDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}';
  }
}
