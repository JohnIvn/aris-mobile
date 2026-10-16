import 'status.dart';

/// A single AR/DTR submission for one payroll period — the list
/// screen shows the summary fields, the detail screen shows all of it.
class ReportItem {
  final String id;
  final String periodLabel;
  final PipelineStage stage;
  final DateTime updatedAt;

  /// Reason given when [stage] is [PipelineStage.rejected]. Rejections
  /// always carry remarks — null in every other stage.
  final String? rejectionRemarks;

  final String professorName;
  final String professorId;
  final String department;
  final String position;
  final DateTime shiftDate;
  final String reportNarrative;

  /// Total Tally of DTR time for the period, in hours.
  final double dtrTotalHours;

  /// Total Tally of the ARs (accomplishments/tasks logged) for the period.
  final int arTaskTally;

  /// Only reaches [PayrollStatus.available] once [stage] is
  /// [PipelineStage.completed] (all three admins verified).
  final PayrollStatus payrollStatus;
  final DateTime? payrollAvailableAt;
  final DateTime? payrollReceivedAt;

  const ReportItem({
    required this.id,
    required this.periodLabel,
    required this.stage,
    required this.updatedAt,
    this.rejectionRemarks,
    required this.professorName,
    required this.professorId,
    required this.department,
    required this.position,
    required this.shiftDate,
    required this.reportNarrative,
    required this.dtrTotalHours,
    required this.arTaskTally,
    required this.payrollStatus,
    this.payrollAvailableAt,
    this.payrollReceivedAt,
  });
}

