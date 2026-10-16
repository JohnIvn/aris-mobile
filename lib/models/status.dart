/// Shared pipeline: Draft -> Submitted -> Department -> HR ->
/// Accounting -> Completed. The AR and DTR for a period are
/// submitted together and move through this pipeline together —
/// there's no separate AR-only or DTR-only stage. Completed means
/// all three admins (Department Secretary, HR, Accounting) have
/// verified, which is also what unlocks [PayrollStatus.available].
enum PipelineStage {
  draft,
  submitted,
  department,
  hr,
  accounting,
  completed,
  rejected,
}

extension PipelineStageX on PipelineStage {
  String get label {
    switch (this) {
      case PipelineStage.draft:
        return 'Draft';
      case PipelineStage.submitted:
        return 'Submitted';
      case PipelineStage.department:
        return 'For Department Verification';
      case PipelineStage.hr:
        return 'For HR Verification';
      case PipelineStage.accounting:
        return 'Pending Accounting';
      case PipelineStage.completed:
        return 'Completed';
      case PipelineStage.rejected:
        return 'Rejected';
    }
  }

  /// Which status color this stage should render with — screens
  /// read `colors.<field>` via this instead of hardcoding a color.
  StatusColorKind get colorKind {
    switch (this) {
      case PipelineStage.completed:
        return StatusColorKind.success;
      case PipelineStage.rejected:
        return StatusColorKind.error;
      case PipelineStage.department:
      case PipelineStage.hr:
      case PipelineStage.accounting:
        return StatusColorKind.warning;
      case PipelineStage.submitted:
        return StatusColorKind.info;
      case PipelineStage.draft:
        return StatusColorKind.neutral;
    }
  }
}

enum StatusColorKind { success, warning, error, info, neutral }

/// Payroll only ever reaches [available] once the AR+DTR
/// [PipelineStage] for that period is `completed` — i.e. all three
/// admins have verified. [received] is a separate, later state once
/// the professor has actually gotten paid.
enum PayrollStatus { notAvailable, available, received }

extension PayrollStatusX on PayrollStatus {
  String get label {
    switch (this) {
      case PayrollStatus.notAvailable:
        return 'Not Yet Available';
      case PayrollStatus.available:
        return 'Available for Release';
      case PayrollStatus.received:
        return 'Received';
    }
  }

  StatusColorKind get colorKind {
    switch (this) {
      case PayrollStatus.notAvailable:
        return StatusColorKind.neutral;
      case PayrollStatus.available:
        return StatusColorKind.info;
      case PayrollStatus.received:
        return StatusColorKind.success;
    }
  }
}
