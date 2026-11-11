import 'package:flutter/material.dart';

import '../models/ar_item.dart';
import '../models/report_item.dart';
import '../models/status.dart';
import '../services/ar_service.dart';
import '../theme/app_colors.dart';
import '../theme/theme_scope.dart';
import '../widgets/section_card.dart';
import '../widgets/status_badge.dart';
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
      body: ArRecordsView(report: widget.report),
    );
  }
}

class ArRecordsView extends StatefulWidget {
  final ReportItem report;

  const ArRecordsView({super.key, required this.report});

  @override
  State<ArRecordsView> createState() => _ArRecordsViewState();
}

class _ArRecordsViewState extends State<ArRecordsView> {
  @override
  Widget build(BuildContext context) {
    final colors = ThemeScope.colorsOf(context);
    final service = ArService();
    final ars = service.forReport(widget.report);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        if (ars.isNotEmpty)
          SectionCard(
            title: 'AR Records',
            child: Column(
              children: [
                for (var i = 0; i < ars.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 20,
                      thickness: 1,
                      color: colors.border.withValues(alpha: 0.5),
                    ),
                  _arTile(context, colors, ars[i]),
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
    );
  }

  Widget _arTile(BuildContext context, AppColors colors, ArItem ar) {
    final status = _statusFor(ar);
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
                    const SizedBox(height: 8),
                    StatusBadge(label: status.$1, kind: status.$2),
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

  (String, StatusColorKind) _statusFor(ArItem ar) {
    final current = ar.statusAt(DateTime.now());
    if (current == ArStatus.approved) {
      return ('Approved', StatusColorKind.success);
    }
    if (current == ArStatus.invalid) {
      return ('Invalid', StatusColorKind.error);
    }
    if (current == ArStatus.forResubmission) {
      return ('For resubmission', StatusColorKind.error);
    }
    if (current == ArStatus.forwarded) {
      return ('Forwarded', StatusColorKind.neutral);
    }

    final stage = ar.currentApproval?.stage.label ?? 'Checker';
    return (stage, StatusColorKind.info);
  }
}
