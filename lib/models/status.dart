/// Shared pipeline: Draft -> Submitted -> Department -> HR ->
/// Accounting -> Completed. Used by both AR and DTR so the
/// dashboard can render them consistently.
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
