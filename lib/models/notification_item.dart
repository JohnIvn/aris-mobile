import 'status.dart';

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final StatusColorKind kind;
  final String? deepLinkReportId;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.kind,
    this.deepLinkReportId,
  });
}
