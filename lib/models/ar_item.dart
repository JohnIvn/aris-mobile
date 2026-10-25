import 'status.dart';

enum ApprovalStage { department, hr, accounting }

extension ApprovalStageX on ApprovalStage {
  String get label => switch (this) {
    ApprovalStage.department => 'Department',
    ApprovalStage.hr => 'HR',
    ApprovalStage.accounting => 'Accounting',
  };
}

enum ApprovalDecision { pending, approved, rejected }

/// Set by the reviewer when rejecting.
enum RejectionKind { resubmission, invalid }

enum ArStatus { inReview, approved, forResubmission, invalid, forwarded }

extension ArStatusX on ArStatus {
  StatusColorKind get colorKind => switch (this) {
    ArStatus.inReview => StatusColorKind.info,
    ArStatus.approved => StatusColorKind.success,
    ArStatus.forResubmission => StatusColorKind.error,
    ArStatus.invalid => StatusColorKind.error,
    ArStatus.forwarded => StatusColorKind.neutral,
  };

  /// Still part of the current submission batch (counts toward verification).
  bool get isActive => this == ArStatus.inReview || this == ArStatus.approved;
}

class ArApproval {
  final ApprovalStage stage;
  final ApprovalDecision decision;
  final DateTime? decidedAt;
  final String? reviewer;
  final String? remarks;

  const ArApproval({
    required this.stage,
    this.decision = ApprovalDecision.pending,
    this.decidedAt,
    this.reviewer,
    this.remarks,
  });

  ArApproval reset() => ArApproval(stage: stage);
}

class ArItem {
  final String id;
  final String reportId;

  // Mirrors the report_entries table.
  final String course;
  final String code;
  final String program;
  final int year;
  final String section;
  final int units;
  final String day;
  final double shiftHours;
  final String shiftStart; // HH:mm
  final String shiftEnd; // HH:mm
  final String campus;
  final DateTime classDate;
  final String topics;
  final String description;

  final DateTime submittedAt;
  final List<ArApproval> approvals; // department -> hr -> accounting
  final RejectionKind? rejectionKind;

  /// Semi-monthly cutoff the AR must be resubmitted before (resubmission only).
  final DateTime? resubmitBy;
  final int resubmissions;

  const ArItem({
    required this.id,
    required this.reportId,
    required this.course,
    required this.code,
    required this.program,
    required this.year,
    required this.section,
    required this.units,
    required this.day,
    required this.shiftHours,
    required this.shiftStart,
    required this.shiftEnd,
    required this.campus,
    required this.classDate,
    required this.topics,
    required this.description,
    required this.submittedAt,
    required this.approvals,
    this.rejectionKind,
    this.resubmitBy,
    this.resubmissions = 0,
  });

  ArApproval? get rejection {
    for (final a in approvals) {
      if (a.decision == ApprovalDecision.rejected) return a;
    }
    return null;
  }

  /// First stage still waiting for a decision (null if rejected or all done).
  ArApproval? get currentApproval {
    if (rejection != null) return null;
    for (final a in approvals) {
      if (a.decision == ApprovalDecision.pending) return a;
    }
    return null;
  }

  double get progress =>
      approvals.where((a) => a.decision == ApprovalDecision.approved).length /
      approvals.length;

  /// A missed resubmission deadline automatically becomes [ArStatus.forwarded].
  ArStatus statusAt(DateTime now) {
    if (rejection != null) {
      if (rejectionKind == RejectionKind.invalid) return ArStatus.invalid;
      final by = resubmitBy;
      if (by != null && now.isAfter(by)) return ArStatus.forwarded;
      return ArStatus.forResubmission;
    }
    if (approvals.every((a) => a.decision == ApprovalDecision.approved)) {
      return ArStatus.approved;
    }
    return ArStatus.inReview;
  }

  /// Cutoff of the submission period after the one this AR missed / was removed from.
  DateTime get nextPeriodCutoff => semiMonthlyCutoff(
    (resubmitBy ?? semiMonthlyCutoff(submittedAt)).add(const Duration(days: 1)),
  );

  /// Resubmission resumes at the stage that rejected it.
  ArItem resubmitted(DateTime now) {
    final idx = approvals.indexWhere(
      (a) => a.decision == ApprovalDecision.rejected,
    );
    return ArItem(
      id: id,
      reportId: reportId,
      course: course,
      code: code,
      program: program,
      year: year,
      section: section,
      units: units,
      day: day,
      shiftHours: shiftHours,
      shiftStart: shiftStart,
      shiftEnd: shiftEnd,
      campus: campus,
      classDate: classDate,
      topics: topics,
      description: description,
      submittedAt: now,
      approvals: [
        for (var i = 0; i < approvals.length; i++)
          (idx >= 0 && i >= idx) ? approvals[i].reset() : approvals[i],
      ],
      rejectionKind: null,
      resubmitBy: null,
      resubmissions: resubmissions + 1,
    );
  }
}

/// Semi-monthly deadline: the 15th, or the last day of the month.
DateTime semiMonthlyCutoff(DateTime d) {
  final lastDay = DateTime(d.year, d.month + 1, 0).day;
  final day = d.day <= 15 ? 15 : lastDay;
  return DateTime(d.year, d.month, day, 23, 59, 59);
}

String formatShortDate(DateTime d) {
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
