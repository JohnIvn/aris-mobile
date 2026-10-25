import 'status.dart';

class NotificationItem {
  final String id;
  final String type;
  final String title;
  final String body;
  final DateTime timestamp;
  final StatusColorKind kind;
  final bool isRead;
  final String? reportId;

  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.kind,
    this.isRead = false,
    this.reportId,
  });

  /// Report to open when tapped (only AR notifications carry one).
  String? get deepLinkReportId => reportId;

  bool get opensPayroll => type.startsWith('payroll_');

  NotificationItem copyWith({bool? isRead}) => NotificationItem(
    id: id,
    type: type,
    title: title,
    body: body,
    timestamp: timestamp,
    kind: kind,
    isRead: isRead ?? this.isRead,
    reportId: reportId,
  );

  factory NotificationItem.fromJson(Map<String, dynamic> j) {
    final type = (j['type'] ?? '').toString();
    final title = (j['title'] ?? '').toString().trim();
    final created = j['created_at']?.toString();
    final reportId = j['report_id']?.toString();

    return NotificationItem(
      id: j['id'].toString(),
      type: type,
      title: title.isEmpty ? 'Notification' : title,
      body: (j['description'] ?? '').toString(),
      timestamp:
          (created != null ? DateTime.tryParse(created) : null)?.toLocal() ??
          DateTime.now(),
      kind: _kindFor(type),
      isRead: j['is_read'] == true,
      reportId: (reportId == null || reportId.isEmpty) ? null : reportId,
    );
  }

  static StatusColorKind _kindFor(String type) {
    switch (type) {
      case 'ar_approved':
      case 'payroll_ready':
        return StatusColorKind.success;
      case 'ar_rejected':
      case 'payroll_rejected':
        return StatusColorKind.error;
      case 'ar_submitted':
      case 'ar_department_secretary':
      case 'ar_hr':
      case 'ar_accounting':
      case 'ar_updated':
      case 'ar_returned':
        return StatusColorKind.warning;
      case 'ar_forwarded':
      case 'ar_status_changed':
      case 'payroll_updated':
      case 'payroll_moved':
      case 'payroll_status_changed':
        return StatusColorKind.info;
      default:
        return StatusColorKind.neutral;
    }
  }
}
