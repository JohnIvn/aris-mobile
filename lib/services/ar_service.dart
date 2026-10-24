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

  static const _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  // (course, code, program, year, section, units, topics, description)
  static const _courses = [
    (
      'Web Systems and Technologies',
      'IT 301',
      'BSIT',
      3,
      'A',
      3,
      'RESTful APIs and routing',
      'Delivered the lecture and guided the class through the hands-on exercise.',
    ),
    (
      'Database Management Systems',
      'IT 204',
      'BSIT',
      2,
      'B',
      3,
      'Normalization and joins',
      'Discussed normal forms and facilitated the in-class query activity.',
    ),
    (
      'Capstone Project 1',
      'IT 401',
      'BSIT',
      4,
      'A',
      3,
      'Proposal defense preparation',
      'Advised the groups on their proposal documents and revisions.',
    ),
    (
      'Data Structures and Algorithms',
      'CS 202',
      'BSCS',
      2,
      'A',
      3,
      'Trees and graph traversal',
      'Lectured on traversal strategies and checked the seatwork outputs.',
    ),
    (
      'Programming Laboratory',
      'IT 102L',
      'BSIT',
      1,
      'C',
      1,
      'Loops and arrays',
      'Supervised the laboratory session and assessed the exercises.',
    ),
    (
      'Information Assurance',
      'IT 405',
      'BSIT',
      4,
      'B',
      3,
      'Access control models',
      'Proctored the quiz and discussed the results afterwards.',
    ),
    (
      'Software Engineering',
      'IT 303',
      'BSIT',
      3,
      'B',
      3,
      'Agile and sprint planning',
      'Facilitated the sprint planning workshop with the project teams.',
    ),
  ];

  List<ArItem> _generate(ReportItem r) {
    final now = DateTime.now();
    return [for (var i = 0; i < r.arTaskTally; i++) _mockAr(r, i, now)];
  }

  ArItem _mockAr(ReportItem r, int i, DateTime now) {
    final c = _courses[i % _courses.length];
    final base = DateTime(r.shiftDate.year, r.shiftDate.month, r.shiftDate.day);
    final classDate = base.add(Duration(days: i));

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
                ? 'Class does not match the biometric record for this date.'
                : 'Please attach the missing details of the activity and resubmit.',
          )
        else
          ArApproval(stage: stages[s]),
    ];

    return ArItem(
      id: '${r.id}-ar-${i + 1}',
      reportId: r.id,
      course: c.$1,
      code: c.$2,
      program: c.$3,
      year: c.$4,
      section: c.$5,
      units: c.$6,
      day: _weekdays[classDate.weekday - 1],
      shiftHours: 3,
      shiftStart: '08:00',
      shiftEnd: '11:00',
      campus: 'Main Campus',
      classDate: classDate,
      topics: c.$7,
      description: c.$8,
      submittedAt: now.subtract(const Duration(days: 5)),
      approvals: approvals,
      rejectionKind: kind,
      resubmitBy: by,
    );
  }
}
