import 'package:flutter/material.dart';

import '../models/ar_item.dart';
import '../models/report_item.dart';
import '../services/ar_service.dart';
import '../theme/app_colors.dart';
import '../theme/theme_scope.dart';
import '../widgets/section_card.dart';
import '../widgets/status_badge.dart';

class ArDetailScreen extends StatefulWidget {
  final ReportItem report;
  final String arId;

  const ArDetailScreen({super.key, required this.report, required this.arId});

  @override
  State<ArDetailScreen> createState() => _ArDetailScreenState();
}

class _ArDetailScreenState extends State<ArDetailScreen> {
  ArItem? get _ar => ArService().find(widget.report, widget.arId);

  @override
  void initState() {
    super.initState();
    // Prompt right away when the AR was rejected.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ar = _ar;
      if (!mounted || ar == null) return;
      if (ar.statusAt(DateTime.now()) != ArStatus.inReview &&
          ar.statusAt(DateTime.now()) != ArStatus.approved) {
        _showPrompt();
      }
    });
  }

  Future<void> _showPrompt() async {
    final ar = _ar;
    if (ar == null) return;
    final now = DateTime.now();
    final status = ar.statusAt(now);
    final remarks = ar.rejection?.remarks;

    final String title;
    final String body;
    switch (status) {
      case ArStatus.forResubmission:
        title = 'AR rejected';
        body =
            '${ar.rejection?.stage.label} rejected this AR.\n\n'
            '${remarks ?? ''}\n\n'
            'Resubmit before ${formatShortDate(ar.resubmitBy!)}. If the '
            'cutoff is missed, it is removed from this batch and forwarded '
            'to the next submission period. Payroll for your other ARs is '
            'not affected.';
      case ArStatus.invalid:
        title = 'AR marked invalid';
        body =
            '${remarks ?? ''}\n\nIt was removed from this batch so payroll '
            'is not delayed. You can file it again in the next submission '
            'period (cutoff ${formatShortDate(ar.nextPeriodCutoff)}).';
      case ArStatus.forwarded:
        title = 'Resubmission deadline missed';
        body =
            'The cutoff on ${formatShortDate(ar.resubmitBy!)} has passed. '
            'This AR was automatically forwarded to the next submission '
            '(cutoff ${formatShortDate(ar.nextPeriodCutoff)}).';
      default:
        return;
    }

    final canResubmit = status == ArStatus.forResubmission;
    final resubmit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(canResubmit ? 'Later' : 'Close'),
          ),
          if (canResubmit)
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Resubmit'),
            ),
        ],
      ),
    );

    if (resubmit == true && mounted) {
      ArService().resubmit(widget.report, widget.arId);
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AR resubmitted for review.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeScope.colorsOf(context);
    final ar = _ar;
    final report = widget.report;

    if (ar == null) {
      return Scaffold(
        backgroundColor: colors.canvas,
        appBar: AppBar(backgroundColor: colors.canvas),
        body: Center(
          child: Text(
            'AR not found.',
            style: TextStyle(color: colors.textSecondary),
          ),
        ),
      );
    }

    final now = DateTime.now();
    final status = ar.statusAt(now);

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
          ar.course,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          if (!status.isActive) _attentionCard(colors, ar, status),
          
          SectionCard(
            title: 'Class Details',
            child: Column(
              children: [
                _detailRow(colors, 'Course', ar.course),
                _gap(colors),
                _detailRow(colors, 'Code', ar.code),
                _gap(colors),
                _detailRow(
                  colors,
                  'Program',
                  '${ar.program} ${ar.year}-${ar.section}',
                ),
                _gap(colors),
                _detailRow(colors, 'Units', '${ar.units}'),
                _gap(colors),
                _detailRow(colors, 'Campus', ar.campus),
              ],
            ),
          ),
          SectionCard(
            title: 'Shift Details',
            child: Column(
              children: [
                _detailRow(colors, 'Day', ar.day),
                _gap(colors),
                _detailRow(colors, 'Date', formatShortDate(ar.classDate)),
                _gap(colors),
                _detailRow(colors, 'Time', '${ar.shiftStart} – ${ar.shiftEnd}'),
                _gap(colors),
                _detailRow(
                  colors,
                  'Hours',
                  '${ar.shiftHours.toStringAsFixed(1)} hrs',
                ),
                _gap(colors),
                _detailRow(
                  colors,
                  'Submitted',
                  formatShortDate(ar.submittedAt),
                ),
                if (ar.resubmissions > 0) ...[
                  _gap(colors),
                  _detailRow(colors, 'Resubmissions', '${ar.resubmissions}'),
                ],
              ],
            ),
          ),
          SectionCard(
            title: 'Professor Details',
            child: Column(
              children: [
                _detailRow(colors, 'Professor Name', report.professorName),
                _gap(colors),
                _detailRow(colors, 'Professor ID', report.professorId),
                _gap(colors),
                _detailRow(colors, 'Department', report.department),
                _gap(colors),
                _detailRow(colors, 'Position', report.position),
              ],
            ),
          ),
          SectionCard(
            title: 'Topics',
            child: Text(
              ar.topics,
              style: TextStyle(color: colors.text, fontSize: 14, height: 1.5),
            ),
          ),
          SectionCard(
            title: 'Description',
            child: Text(
              ar.description,
              style: TextStyle(color: colors.text, fontSize: 14, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _attentionCard(AppColors colors, ArItem ar, ArStatus status) {
    final isError = status != ArStatus.forwarded;
    final color = isError ? colors.error : colors.textSecondary;
    final (title, text) = switch (status) {
      ArStatus.forResubmission => (
        'Needs resubmission',
        'Resubmit before ${formatShortDate(ar.resubmitBy!)}, or it is '
            'automatically forwarded to the next submission.',
      ),
      ArStatus.invalid => (
        'Invalid',
        'Removed from this batch. You can file it again next period '
            '(cutoff ${formatShortDate(ar.nextPeriodCutoff)}).',
      ),
      _ => (
        'Forwarded to next submission',
        'Resubmission deadline was missed. Carried to the period ending '
            '${formatShortDate(ar.nextPeriodCutoff)}.',
      ),
    };

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.schedule,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: TextStyle(color: colors.text, fontSize: 13.5, height: 1.45),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: status == ArStatus.forResubmission
                ? FilledButton(
                    onPressed: _showPrompt,
                    child: const Text('Resubmit'),
                  )
                : OutlinedButton(
                    onPressed: _showPrompt,
                    child: const Text('View details'),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _approvalRow(AppColors colors, ArApproval a, bool isCurrent) {
    final (icon, color) = switch (a.decision) {
      ApprovalDecision.approved => (Icons.check_circle, colors.success),
      ApprovalDecision.rejected => (Icons.cancel, colors.error),
      ApprovalDecision.pending =>
        isCurrent
            ? (Icons.schedule, colors.warning)
            : (Icons.radio_button_unchecked, colors.textSecondary),
    };

    final String subtitle;
    if (a.decision == ApprovalDecision.pending) {
      subtitle = isCurrent ? 'Awaiting review' : 'Not yet reached';
    } else {
      final who = a.reviewer ?? '';
      final when = a.decidedAt == null ? '' : formatShortDate(a.decidedAt!);
      subtitle = [who, when].where((s) => s.isNotEmpty).join(' · ');
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                a.stage.label,
                style: TextStyle(
                  color: colors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(color: colors.textSecondary, fontSize: 12.5),
              ),
              if (a.decision == ApprovalDecision.rejected &&
                  a.remarks != null) ...[
                const SizedBox(height: 6),
                Text(
                  a.remarks!,
                  style: TextStyle(
                    color: colors.error,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _gap(AppColors colors) => Divider(
    height: 24,
    thickness: 1,
    color: colors.border.withValues(alpha: 0.5),
  );

  Widget _detailRow(AppColors colors, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: colors.textSecondary, fontSize: 13.5),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: colors.text,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
