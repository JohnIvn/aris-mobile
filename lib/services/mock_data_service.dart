import '../models/notification_item.dart';
import '../models/status.dart';

/// Placeholder data source. Swap the body of each method for a
/// real DB/API call once persistence is wired up — screens only
/// ever depend on this class, never on raw mock lists directly,
/// so that swap won't touch UI code.
class MockDataService {

  List<NotificationItem> getNotifications() {
    return [
      NotificationItem(
        id: 'n1',
        title: 'Accomplishment Report Rejected',
        body: 'Your AR for Aug 16–31 requires corrections.',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        kind: StatusColorKind.error,
        deepLinkReportId: 'ar-2026-08b',
      ),
      NotificationItem(
        id: 'n2',
        title: 'DTR Verified',
        body: 'Your DTR has been verified by the Department Secretary.',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        kind: StatusColorKind.success,
      ),
      NotificationItem(
        id: 'n3',
        title: 'AR Approved by HR',
        body: 'Your Accomplishment Report has proceeded to Accounting.',
        timestamp: DateTime(2026, 8, 25),
        kind: StatusColorKind.info,
        deepLinkReportId: 'ar-2026-08a',
      ),
    ];
  }
}
