import 'package:flutter/material.dart';

import '../models/ar_item.dart';
import '../models/report_item.dart';
import '../services/ar_service.dart';
import '../theme/app_colors.dart';
import '../theme/theme_scope.dart';
import '../widgets/section_card.dart';
import 'ar_detail_screen.dart';

class ArListScreen extends StatefulWidget {
  final ReportItem report;

  const ArListScreen({super.key, required this.report});

  @override
  State<ArListScreen> createState() => _ArListScreenState();
}

class _ArListScreenState extends State<ArListScreen> {
  @override
  Widget build(BuildContext context) {
    final colors = ThemeScope.colorsOf(context);
    final now = DateTime.now();
    final service = ArService();
    final ars = service.forReport(widget.report);

    List<ArItem> inGroup(Set<ArStatus> s) =>
        ars.where((a) => s.contains(a.statusAt(now))).toList();

    final groups = <(String, String?, List<ArItem>)>[
      (
        'For resubmission',
        'Resubmit before the semi-monthly cutoff, otherwise it moves to the next period.',
        inGroup({ArStatus.forResubmission}),
      ),
      ('Submitted ARs', null, inGroup({ArStatus.inReview, ArStatus.approved})),
      (
        'Invalid',
        'Removed from this batch so payroll is not delayed. Can be filed again next period.',
        inGroup({ArStatus.invalid}),
      ),
      (
        'Forwarded to next period',
        'Resubmission deadline was missed; automatically carried to the next submission.',
        inGroup({ArStatus.forwarded}),
      ),
    ];

    return Scaffold(
      backgroundColor: colors.canvas,
      appBar: AppBar(
        backgroundColor: colors.canvas,
        foregroundColor: colors.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Text(
          'ARs · ${widget.report.periodLabel}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          for (final g in groups)
            if (g.$3.isNotEmpty)
              SectionCard(
                title: '${g.$1} (${g.$3.length})',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (g.$2 != null) ...[
                      Text(
                        g.$2!,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    for (var i = 0; i < g.$3.length; i++) ...[
                      if (i > 0)
                        Divider(
                          height: 20,
                          thickness: 1,
                          color: colors.border.withValues(alpha: 0.5),
                        ),
                      _arTile(context, colors, g.$3[i], now),
                    ],
                  ],
                ),
              ),
          if (ars.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'No ARs submitted for this report.',
                  style: TextStyle(color: colors.textSecondary, fontSize: 13),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _arTile(
    BuildContext context,
    AppColors colors,
    ArItem ar,
    DateTime now,
  ) {
    final status = ar.statusAt(now);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  ArDetailScreen(report: widget.report, arId: ar.id),
            ),
          );
          if (mounted) setState(() {});
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ar.course,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.text,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${ar.code} · ${ar.program} ${ar.year}-${ar.section}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Day and class date
                    Text(
                      '${ar.day}, ${formatShortDate(ar.classDate)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),

                    const SizedBox(height: 2),

                    // Class period
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 13,
                          color: colors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${ar.shiftStart} – ${ar.shiftEnd}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (status.isActive) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: ar.progress,
                          minHeight: 5,
                          backgroundColor: colors.border.withValues(alpha: 0.5),
                          valueColor: AlwaysStoppedAnimation(
                            status == ArStatus.approved
                                ? colors.success
                                : colors.accentActive,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.chevron_right, color: colors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
