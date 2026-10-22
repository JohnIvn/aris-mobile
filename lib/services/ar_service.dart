import '../models/ar_item.dart';
import '../models/report_item.dart';
import '../models/status.dart';

class ArSummary {
  final int total;
  final int approved;
  final int inReview;
  final int forResubmission;
  final int invalid;
  final int forwarded;

  /// Average approval progress of the ARs still in the batch (0-100).
  final int percent;

  const ArSummary({
    required this.total,
    required this.approved,
    required this.inReview,
    required this.forResubmission,
    required this.invalid,
    required this.forwarded,
    required this.percent,
  });

  int get active => approved + inReview;
  bool get needsAction => forResubmission > 0;
}

/// Mock source of ARs, generated from each report's `arTaskTally`.
/// Replace [_generate] with the real data source; the rest stays.
class ArService {
  static final ArService _instance = ArService._();
  factory ArService() => _instance;
  ArService._();

  final Map<String, List<ArItem>> _cache = {};

  List<ArItem> forReport(ReportItem r) =>
      _cache.putIfAbsent(r.id, () => _generate(r));

  ArItem? find(ReportItem r, String arId) {
    for (final a in forReport(r)) {
      if (a.id == arId) return a;
    }
    return null;
  }

  void resubmit(ReportItem r, String arId) {
    final list = forReport(r);
    final i = list.indexWhere((a) => a.id == arId);
    if (i >= 0) list[i] = list[i].resubmitted(DateTime.now());
  }

  ArSummary summarize(ReportItem r) {
    final now = DateTime.now();
    final ars = forReport(r);
    var approved = 0, inReview = 0, resub = 0, invalid = 0, forwarded = 0;
    var progressSum = 0.0;
    for (final a in ars) {
      switch (a.statusAt(now)) {
        case ArStatus.approved:
          approved++;
          progressSum += a.progress;
        case ArStatus.inReview:
          inReview++;
          progressSum += a.progress;
        case ArStatus.forResubmission:
          resub++;
        case ArStatus.invalid:
          invalid++;
        case ArStatus.forwarded:
          forwarded++;
      }
    }
    final active = approved + inReview;
    return ArSummary(
      total: ars.length,
      approved: approved,
      inReview: inReview,
      forResubmission: resub,
      invalid: invalid,
      forwarded: forwarded,
      percent: active == 0 ? 0 : (progressSum / active * 100).round(),
    );
  }

  // ---- mock generation ----------------------------------------------------

  static const _titles = [
    'Lecture delivery',
    'Consultation hours',
    'Thesis advising',
    'Curriculum review',
    'Laboratory supervision',
    'Exam proctoring',
    'Department meeting',
  ];

  List<ArItem> _generate(ReportItem r) {
    final now = DateTime.now();
    return [
      for (var i = 0; i < r.arTaskTally; i++) _mockAr(r, i, now),
    ];
  }

  ArItem _mockAr(ReportItem r, int i, DateTime now) {
    final title = _titles[i % _titles.length];
    final base = DateTime(r.shiftDate.year, r.shiftDate.month, r.shiftDate.day);

    // How many stages approved, and whether a stage then rejected.
    int approvedCount;
    RejectionKind? kind;
    DateTime? by;
    switch (r.stage) {
      case PipelineStage.completed:
        approvedCount = 3;
      case PipelineStage.draft:
      case PipelineStage.submitted:
        approvedCount = 0;
      default:
        switch (i % 7) {
          case 0:
            approvedCount = 3;
          case 1:
            approvedCount = 1;
          case 2:
            approvedCount = 0;
          case 3:
            approvedCount = 2;
          case 4:
            approvedCount = 1;
            kind = RejectionKind.resubmission;
            by = now.add(const Duration(days: 2));
          case 5:
            approvedCount = 0;
            kind = RejectionKind.invalid;
          default:
            approvedCount = 2;
            kind = RejectionKind.resubmission;
            by = now.subtract(const Duration(days: 1));
        }
    }

    final stages = ApprovalStage.values;
    final approvals = <ArApproval>[
      for (var s = 0; s < stages.length; s++)
        if (s < approvedCount)
          ArApproval(
            stage: stages[s],
            decision: ApprovalDecision.approved,
            decidedAt: now.subtract(Duration(days: 4 - s)),
            reviewer: '${stages[s].label} Reviewer',
          )
        else if (s == approvedCount && kind != null)
          ArApproval(
            stage: stages[s],
            decision: ApprovalDecision.rejected,
            decidedAt: now.subtract(const Duration(days: 1)),
            reviewer: '${stages[s].label} Reviewer',
            remarks: kind == RejectionKind.invalid
                ? 'Shift does not match the biometric record for this date.'
                : 'Please attach the missing details of the activity and resubmit.',
          )
        else
          ArApproval(stage: stages[s]),
    ];

    return ArItem(
      id: '${r.id}-ar-${i + 1}',
      reportId: r.id,
      title: '${i + 1}. $title',
      narrative:
          '$title for the period. Completed the scheduled tasks and '
          'submitted the corresponding outputs.',
      shiftDate: base.add(Duration(days: i)),
      shiftTime: '8:00 AM – 5:00 PM',
      shiftHours: 8,
      submittedAt: now.subtract(const Duration(days: 5)),
      approvals: approvals,
      rejectionKind: kind,
      resubmitBy: by,
    );
  }
}
