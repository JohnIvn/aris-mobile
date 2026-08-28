import 'status.dart';

class ReportItem {
  final String id;
  final String periodLabel;
  final PipelineStage stage;
  final DateTime updatedAt;

  const ReportItem({
    required this.id,
    required this.periodLabel,
    required this.stage,
    required this.updatedAt,
  });
}
