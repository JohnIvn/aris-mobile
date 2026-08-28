import '../models/dtr_entry.dart';
import '../models/notification_item.dart';
import '../models/report_item.dart';
import '../models/status.dart';

/// Placeholder data source. Swap the body of each method for a
/// real DB/API call once persistence is wired up — screens only
/// ever depend on this class, never on raw mock lists directly,
/// so that swap won't touch UI code.
class MockDataService {
  static const currentUserName = 'Matthew';
  static const currentPayrollPeriod = 'Aug 16 – Aug 31';

  List<ReportItem> getReports() {
    return [
      ReportItem(
        id: 'ar-2026-08b',
        periodLabel: 'Aug 16 – Aug 31',
        stage: PipelineStage.hr,
        updatedAt: DateTime(2026, 8, 27),
        professorName: 'Matthew D. Santos',
        professorId: 'PROF-00214',
        department: 'College of Computer Studies',
        position: 'Part-time Instructor',
        shiftDate: DateTime(2026, 8, 27),
        reportNarrative:
            'Conducted lecture and lab sessions for IT elective courses, '
            'consulted with 3 thesis groups, and finalized midterm exam '
            'materials for submission to the department.',
        dtrTotalHours: 62.5,
        arTaskTally: 9,
      ),
      ReportItem(
        id: 'ar-2026-08a',
        periodLabel: 'Aug 1 – Aug 15',
        stage: PipelineStage.completed,
        updatedAt: DateTime(2026, 8, 16),
        professorName: 'Matthew D. Santos',
        professorId: 'PROF-00214',
        department: 'College of Computer Studies',
        position: 'Part-time Instructor',
        shiftDate: DateTime(2026, 8, 15),
        reportNarrative:
            'Delivered scheduled lectures, proctored the first long exam, '
            'and submitted grade sheets for the previous grading period.',
        dtrTotalHours: 64.0,
        arTaskTally: 11,
      ),
      ReportItem(
        id: 'ar-2026-07b',
        periodLabel: 'Jul 16 – Jul 31',
        stage: PipelineStage.rejected,
        updatedAt: DateTime(2026, 8, 1),
        rejectionRemarks:
            'DTR hours for Jul 22 do not match biometric logs. Please '
            'reconcile the discrepancy and resubmit.',
        professorName: 'Matthew D. Santos',
        professorId: 'PROF-00214',
        department: 'College of Computer Studies',
        position: 'Part-time Instructor',
        shiftDate: DateTime(2026, 7, 31),
        reportNarrative:
            'Held regular class sessions and consultation hours; assisted '
            'in department accreditation document preparation.',
        dtrTotalHours: 58.0,
        arTaskTally: 7,
      ),
    ];
  }

  ReportItem? getReportById(String id) {
    for (final report in getReports()) {
      if (report.id == id) return report;
    }
    return null;
  }

  List<DtrEntry> getDtrEntries() {
    return [
      DtrEntry(
        date: DateTime(2026, 8, 16),
        timeIn: '7:58 AM',
        timeOut: '5:02 PM',
        status: DtrDayStatus.present,
      ),
      DtrEntry(
        date: DateTime(2026, 8, 17),
        timeIn: '8:03 AM',
        timeOut: '5:01 PM',
        status: DtrDayStatus.present,
      ),
      DtrEntry(
        date: DateTime(2026, 8, 18),
        timeIn: null,
        timeOut: '5:00 PM',
        status: DtrDayStatus.missing,
      ),
    ];
  }

  PipelineStage getDtrOverallStage() => PipelineStage.department;

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
