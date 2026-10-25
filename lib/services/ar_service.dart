import '../models/ar_item.dart';
import '../models/report_item.dart';

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

/// Holds the ARs of each report. [ReportsStore] fills it via [setForReport]
/// after every fetch.
class ArService {
  static final ArService _instance = ArService._();
  factory ArService() => _instance;
  ArService._();

  final Map<String, List<ArItem>> _cache = {};

  void setForReport(String reportId, List<ArItem> ars) {
    _cache[reportId] = List.of(ars);
  }

  List<ArItem> forReport(ReportItem r) => _cache[r.id] ?? const [];

  ArItem? find(ReportItem r, String arId) {
    for (final a in forReport(r)) {
      if (a.id == arId) return a;
    }
    return null;
  }

  void resubmit(ReportItem r, String arId) {
    final list = _cache[r.id];
    if (list == null) return;
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
}
