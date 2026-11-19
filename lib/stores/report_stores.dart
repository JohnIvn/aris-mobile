import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/ar_item.dart';
import '../models/dtr_entry.dart';
import '../models/report_item.dart';
import '../models/status.dart';
import '../services/ar_service.dart';
import '../services/auth_service.dart';
import '../services/app_env.dart';

/// Single source of truth for reports. Fetches
/// `GET {SERVER_URL}/reports/mobile?offset=&limit=` with the backend JWT from
/// [AuthService], converts each payload into a [ReportItem] and loads its ARs
/// into [ArService].
class ReportsStore extends ChangeNotifier {
  static final ReportsStore _instance = ReportsStore._();
  factory ReportsStore() => _instance;
  ReportsStore._();

  static const _pageSize = 20;

  /// AR-AP-STG-1..4
  static const stageLabels = ['Pending', 'Department', 'HR', 'Accounting'];
  static String stageLabel(int stage) =>
      stage == 0 ? 'Not submitted' : stageLabels[stage - 1];

  /// Set once, before runApp, with the SAME instance that signs in:
  /// `ReportsStore().auth = authService;`
  AuthService? auth;

  List<ReportItem> _reports = const [];
  List<ReportItem> _weeklyCache = const [];
  final Map<String, int> _stageNo = {};
  final Map<String, List<DtrEntry>> _dtr = {};
  final Map<String, String> _periodMonths = {};
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _offset = 0;
  String? _error;

  List<ReportItem> get reports => _reports;
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;

  /// Backend stage of a report: 1 pending, 2 department, 3 HR, 4 accounting.
  int stageOf(ReportItem r) {
    final arCount = ArService().forReport(r).length;
    final dtrCount = dtrEntriesOf(r).length;
    if (arCount == 0 && dtrCount == 0 && r.dtrStatus == null) return 0;
    return _stageNo[r.id] ?? 1;
  }

  /// Daily DTR rows of a report, oldest first.
  List<DtrEntry> dtrEntriesOf(ReportItem r) => _dtr[r.id] ?? const [];

  ReportItem? byId(String id) {
    for (final r in _reports) {
      if (r.id == id) return r;
    }
    return null;
  }

  /// Reloads from the first page.
  Future<void> load() => _fetch(reset: true);

  /// Appends the next page.
  Future<void> loadMore() {
    if (!_hasMore || _reports.isEmpty) return Future.value();
    return _fetch(reset: false);
  }

  /// `PATCH {SERVER_URL}/reports/mobile/payroll?report_id=<id>`
  /// Marks the report's payroll as received. Throws on failure.
  Future<void> markPayrollReceived(String reportId) async {
    final base = AppEnv.serverUrl;
    if (base.isEmpty) {
      throw StateError('SERVER_URL is not set in .env');
    }
    final a = auth;
    final token = a?.token;
    if (a == null || token == null || token.isEmpty) {
      throw Exception('Not signed in.');
    }

    final uri = Uri.parse(
      '${base.replaceAll(RegExp(r'/+$'), '')}/reports/mobile/payroll',
    ).replace(queryParameters: {'report_id': reportId});

    final res = await http
        .patch(
          uri,
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
            ...{'Authorization': 'Bearer $token'},
            ...{'Authorization': 'Bearer $token'},
          },
        )
        .timeout(const Duration(seconds: 15));

    if (res.statusCode == 401) {
      await a.signOut();
      throw Exception('Session expired. Please sign in again.');
    }

    Object? body;
    try {
      body = jsonDecode(res.body);
    } catch (_) {}

    final failed =
        body is Map && (body['ok'] == false || body['status'] == 'failure');
    if (res.statusCode >= 300 || failed) {
      final msg = body is Map
          ? (body['error'] ?? body['message'] ?? 'unknown')
          : 'status ${res.statusCode}';
      throw Exception('Could not update payroll: $msg');
    }

    // Patch locally so the UI updates without refetching pages.
    final i = _reports.indexWhere((r) => r.id == reportId);
    if (i != -1) {
      final r = _reports[i];
      _reports = [..._reports]
        ..[i] = ReportItem(
          id: r.id,
          periodLabel: r.periodLabel,
          stage: r.stage,
          dtrStage: r.dtrStage,
          dtrStatus: r.dtrStatus,
          updatedAt: r.updatedAt,
          rejectionRemarks: r.rejectionRemarks,
          professorName: r.professorName,
          professorId: r.professorId,
          department: r.department,
          position: r.position,
          shiftDate: r.shiftDate,
          reportNarrative: r.reportNarrative,
          dtrTally: r.dtrTally,
          arTaskTally: r.arTaskTally,
          payrollStatus: PayrollStatus.received,
          payrollAvailableAt: r.payrollAvailableAt,
          payrollReceivedAt: r.payrollReceivedAt,
          periodStart: r.periodStart,
          periodEnd: r.periodEnd,
        );
      notifyListeners();
    }
  }

  /// Submits every DTR row in [report]'s payroll period for review.
  Future<void> submitDtrMonth(ReportItem report) async {
    final base = AppEnv.serverUrl;
    if (base.isEmpty) {
      throw StateError('SERVER_URL is not set in .env');
    }
    final a = auth;
    final token = a?.token;
    if (a == null || token == null || token.isEmpty) {
      throw Exception('Not signed in.');
    }

    final entries = dtrEntriesOf(report);
    if (entries.isEmpty) {
      throw Exception('There are no DTR records for ${report.periodLabel}.');
    }
    final year = report.periodStart?.year ?? report.shiftDate.year;
    final month = report.periodStart?.month ?? report.shiftDate.month;
    final isFirstHalf =
        report.periodLabel.toUpperCase().contains(' I') ||
        report.periodStart?.day == 1;
    final firstDay = report.periodStart ?? DateTime(year, month, 1);
    final lastDay =
        report.periodEnd ??
        (isFirstHalf
            ? DateTime(year, month, 15)
            : DateTime(year, month + 1, 0));
    String dateOnly(DateTime date) =>
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    final payload = {
      'periodStart': dateOnly(firstDay),
      'periodEnd': dateOnly(lastDay),
    };
    final uri = Uri.parse(
      '${base.replaceAll(RegExp(r'/+$'), '')}/professor/dtr-submissions',
    );
    debugPrint(
      '[ReportsStore] Submitting DTR data:\n${const JsonEncoder.withIndent('  ').convert(payload)}',
    );
    final res = await http
        .post(
          uri,
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 401) {
      await a.signOut();
      throw Exception('Session expired. Please sign in again.');
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      Object? body;
      try {
        body = jsonDecode(res.body);
      } catch (_) {}
      final message = body is Map
          ? (body['error'] ?? body['message'] ?? 'unknown')
          : 'status ${res.statusCode}';
      throw Exception('Could not submit DTR: $message');
    }
  }

  Future<void> _fetch({required bool reset}) async {
    if (_loading || _loadingMore) return;
    if (reset) {
      _loading = true;
    } else {
      _loadingMore = true;
    }
    _error = null;
    notifyListeners();

    try {
      final base = AppEnv.serverUrl;
      if (base.isEmpty) {
        throw StateError('SERVER_URL is not set in .env');
      }

      final a = auth;
      if (a == null) {
        throw StateError('ReportsStore.auth was never set (wiring issue)');
      }
      final token = a.token;
      if (token == null || token.isEmpty) {
        throw StateError(
          'Not signed in (auth status: ${a.status.name}, user: ${a.user != null})',
        );
      }

      final uri =
          Uri.parse('${base.replaceAll(RegExp(r'/+$'), '')}/reports/mobile')
              .replace(
                queryParameters: {
                  'offset': '${reset ? 0 : _offset}',
                  'limit': '$_pageSize',
                },
              );

      final res = await http
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 401) {
        await a.signOut();
        throw Exception('Session expired. Please sign in again.');
      }
      if (res.statusCode != 200) {
        throw Exception('Server responded ${res.statusCode}');
      }

      final body = jsonDecode(res.body);

      // Backend ErrorHandler shape: {status, ok: false, code, error, data}
      if (body is Map && (body['ok'] == false || body['status'] == 'failure')) {
        throw Exception(
          'Server error ${body['code'] ?? ''}: '
          '${body['error'] ?? body['message'] ?? 'unknown'}',
        );
      }
      final rows = _extractRows(body);
      debugPrint(
        '[ReportsStore] offset=${reset ? 0 : _offset} rows=${rows.length}',
      );

      final parsed = [
        for (final row in rows) _parse(Map<String, dynamic>.from(row as Map)),
      ];

      if (reset) {
        _weeklyCache = parsed;
        _reports = _groupByPeriod(parsed);
        _offset = rows.length;
      } else {
        final known = _weeklyCache.map((r) => r.id).toSet();
        _weeklyCache = [
          ..._weeklyCache,
          ...parsed.where((r) => !known.contains(r.id)),
        ];
        _reports = _groupByPeriod(_weeklyCache);
        _offset += rows.length;
      }
      _hasMore = rows.length >= _pageSize;
    } catch (e, st) {
      debugPrint('[ReportsStore] $e\n$st');
      _error = e.toString();
    } finally {
      _loading = false;
      _loadingMore = false;
      notifyListeners();
    }
  }

  List<ReportItem> _groupByPeriod(List<ReportItem> reports) {
    final grouped = <String, List<ReportItem>>{};
    for (final report in reports) {
      final period = _periodKey(report);
      grouped.putIfAbsent(period, () => []).add(report);
    }

    final now = DateTime.now();
    final curYm =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
    grouped.putIfAbsent('$curYm-I', () => <ReportItem>[]);
    grouped.putIfAbsent('$curYm-II', () => <ReportItem>[]);

    final periods = <ReportItem>[];
    for (final entry in grouped.entries) {
      final periodId = 'period-${entry.key}';
      final range = _periodRange(entry.key);
      final defaultDate = range.$1;

      if (entry.value.isEmpty) {
        final activeReport = ReportItem(
          id: periodId,
          periodLabel: _periodLabel(entry.key),
          stage: PipelineStage.notSubmitted,
          dtrStage: 1,
          dtrStatus: null,
          updatedAt: defaultDate,
          rejectionRemarks: null,
          professorName: auth?.user?.name ?? 'Faculty',
          professorId: auth?.user?.id ?? '',
          department: auth?.user?.department ?? '—',
          position: auth?.user?.position ?? '—',
          shiftDate: defaultDate,
          reportNarrative: '',
          dtrTally: 0.0,
          arTaskTally: 0,
          payrollStatus: PayrollStatus.notAvailable,
          periodStart: range.$1,
          periodEnd: range.$2,
        );
        _periodMonths[periodId] = entry.key;
        _dtr.putIfAbsent(periodId, () => const []);
        periods.add(activeReport);
        continue;
      }

      final items = List<ReportItem>.from(entry.value)
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      final latest = items.first;
      final ars = <ArItem>[];
      final dtr = <DtrEntry>[];
      for (final item in items) {
        ars.addAll(ArService().forReport(item));
        dtr.addAll(
          dtrEntriesOf(item).where(
            (e) => !e.date.isBefore(range.$1) && !e.date.isAfter(range.$2),
          ),
        );
      }
      final rejectedItem = items
          .where((r) => r.stage == PipelineStage.rejected)
          .firstOrNull;
      final stage = rejectedItem != null
          ? PipelineStage.rejected
          : latest.stage;
      final rejectionRemarks =
          rejectedItem?.rejectionRemarks ?? latest.rejectionRemarks;
      final payrollStatus = rejectedItem != null
          ? PayrollStatus.disapproved
          : latest.payrollStatus;

      final periodReport = ReportItem(
        id: periodId,
        periodLabel: _periodLabel(entry.key),
        stage: stage,
        dtrStage: latest.dtrStage,
        dtrStatus: latest.dtrStatus,
        updatedAt: latest.updatedAt,
        rejectionRemarks: rejectionRemarks,
        professorName: latest.professorName,
        professorId: latest.professorId,
        department: latest.department,
        position: latest.position,
        shiftDate: range.$1,
        reportNarrative: latest.reportNarrative,
        dtrTally: items.fold(0.0, (sum, r) => sum + r.dtrTally),
        arTaskTally: ars.length,
        payrollStatus: payrollStatus,
        payrollAvailableAt: latest.payrollAvailableAt,
        payrollReceivedAt: latest.payrollReceivedAt,
        periodStart: range.$1,
        periodEnd: range.$2,
      );
      _periodMonths[periodId] = entry.key;
      ArService().setForReport(periodId, ars);
      _dtr[periodId] = dtr;
      periods.add(periodReport);
    }
    periods.sort((a, b) => b.periodStart!.compareTo(a.periodStart!));
    return periods;
  }

  String _monthKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}';

  String _periodKey(ReportItem report) {
    final mapped = _periodMonths[report.id];
    if (mapped != null) return mapped;
    final periodStart = report.periodStart ?? report.shiftDate;
    final month = _monthKey(periodStart);
    final half =
        periodStart.day <= 15 || report.periodLabel.toUpperCase().contains(' I')
        ? 'I'
        : 'II';
    return '$month-$half';
  }

  (DateTime, DateTime) _periodRange(String key) {
    final parts = key.split('-');
    final year = int.tryParse(parts[0]) ?? DateTime.now().year;
    final month = int.tryParse(parts[1]) ?? DateTime.now().month;
    final firstHalf = parts.length < 3 || parts[2] == 'I';
    final start = DateTime(year, month, firstHalf ? 1 : 16);
    final end = firstHalf
        ? DateTime(year, month, 15)
        : DateTime(year, month + 1, 0);
    return (start, end);
  }

  String _periodLabel(String key) {
    final parts = key.split('-');
    final year = int.tryParse(parts[0]) ?? DateTime.now().year;
    final month = int.tryParse(parts[1]) ?? DateTime.now().month;
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final half = parts.length > 2 ? parts[2] : 'I';
    return '${months[month - 1]} $year $half';
  }

  // ---- parsing ------------------------------------------------------------

  /// Finds the list of reports whether the body is a bare list or wrapped,
  /// e.g. `{data: [...]}` or `{data: {reports: [...]}}`.
  List _extractRows(Object? body) {
    if (body is List) return body;
    if (body is Map) {
      for (final key in const ['data', 'reports', 'items', 'results']) {
        final v = body[key];
        if (v is List) return v;
        if (v is Map) {
          try {
            return _extractRows(v);
          } on FormatException {
            // try the next key
          }
        }
      }
      if (body.containsKey('periodLabel')) return [body];
    }
    throw FormatException(
      'Unexpected response shape: '
      '${body is Map ? 'keys ${body.keys.toList()}' : body.runtimeType}',
    );
  }

  /// 'AR-AP-STG-2' -> 2
  int _stageNumber(String code) =>
      int.tryParse(RegExp(r'(\d+)$').firstMatch(code)?.group(1) ?? '') ?? 1;

  /// Backend stage code -> pipeline stage. Adjust to match your backend.
  PipelineStage _pipelineStage(int n) => switch (n) {
    1 => PipelineStage.submitted,
    2 => PipelineStage.department,
    3 => PipelineStage.hr,
    _ => PipelineStage.accounting,
  };

  String _hm(String t) => t.length >= 5 ? t.substring(0, 5) : t;

  /// '13:30' / '13:30:00' -> '1:30 PM'
  String? _ampm(Object? v) {
    final t = _s(v);
    if (t.isEmpty) return null;
    final p = t.split(':');
    final h = int.tryParse(p[0]);
    if (h == null) return t;
    final m = p.length > 1 ? p[1].padLeft(2, '0') : '00';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:$m ${h < 12 ? 'AM' : 'PM'}';
  }

  DtrEntry _dtrEntry(Map<String, dynamic> e, DateTime fallback) => DtrEntry(
    date: _dt(e['date'], fallback),
    timeIn: _ampm(e['time_in']),
    timeOut: _ampm(e['time_out']),
    status: DtrDayStatus.values.firstWhere(
      (s) => s.name == e['status'],
      orElse: () => DtrDayStatus.present,
    ),
  );

  bool _b(Object? v) => v == true || '$v'.toLowerCase() == 'true';

  String _s(Object? v, [String fallback = '']) => v?.toString() ?? fallback;
  int _i(Object? v, [int fallback = 0]) =>
      v is num ? v.toInt() : int.tryParse('${v ?? ''}') ?? fallback;
  double _d(Object? v, [double fallback = 0]) =>
      v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? fallback;
  DateTime _dt(Object? v, DateTime fallback) =>
      DateTime.tryParse('${v ?? ''}')?.toLocal() ?? fallback;

  ReportItem _parse(Map<String, dynamic> j) {
    final id = _s(j['id']);
    final updatedAt = _dt(j['updatedAt'], DateTime.now());
    final periodStart = _dt(j['periodStart'], updatedAt);
    final periodEndFallback = periodStart.day <= 15
        ? DateTime(periodStart.year, periodStart.month, 15)
        : DateTime(periodStart.year, periodStart.month + 1, 0);
    final periodEnd = _dt(j['periodEnd'], periodEndFallback);
    final periodHalf = periodStart.day <= 15 ? 'I' : 'II';
    final periodKey = '${_monthKey(periodStart)}-$periodHalf';
    _periodMonths[id] = periodKey;
    final stageNo = _stageNumber(_s(j['stage'])).clamp(1, 4);
    _stageNo[id] = stageNo;
    final dtrStage = _stageNumber(
      _s(j['dtr_approval_stage'] ?? j['dtrApprovalStage']),
    ).clamp(1, 4);
    final dtrStageValue = _s(j['dtr_approval_stage'] ?? j['dtrApprovalStage']);
    final dtrStatusValue = _s(j['dtr_status'] ?? j['dtrStatus']);

    final arTally = j['arTally'] as Map?;
    final entries =
        ((j['arEntries'] as List?) ??
                (j['entries'] as List?) ??
                (arTally?['entries'] as List?) ??
                const [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

    // Backend sends no per-AR approvals: stages before the report's current
    // stage count as approved, the rest are pending.
    final stages = ApprovalStage.values;
    final approvedCount = (stageNo - 1).clamp(0, stages.length);

    final ars = <ArItem>[
      for (final e in entries)
        ArItem(
          id: _s(e['id']),
          reportId: id,
          course: _s(e['course']),
          code: _s(e['code']),
          program: _s(e['program']),
          year: _i(e['year']),
          section: _s(e['section']),
          units: _i(e['units']),
          day: _s(e['day']),
          shiftHours: _d(e['shift_hours']),
          shiftStart: _hm(_s(e['shift_start'])),
          shiftEnd: _hm(_s(e['shift_end'])),
          campus: _s(e['campus']),
          classDate: _dt(e['class_date'], updatedAt),
          topics: _s(e['topics']),
          description: _s(e['description']),
          submittedAt: _dt(e['created_at'], updatedAt),
          approvals: [
            for (var s = 0; s < stages.length; s++)
              if (s < approvedCount)
                ArApproval(
                  stage: stages[s],
                  decision: ApprovalDecision.approved,
                  decidedAt: updatedAt,
                )
              else
                ArApproval(stage: stages[s]),
          ],
        ),
    ];
    ArService().setForReport(id, ars);

    // dtrTally is now a plain number (hours); older/error shapes are a map.
    final dtr = j['dtrTally'];
    final dtrHours = dtr is Map
        ? ((dtr['ok'] != false && dtr['status'] != 'failure')
              ? _d(dtr['total_hours'])
              : 0.0)
        : _d(dtr);

    _dtr[id] = [
      for (final e in (j['dtrEntries'] as List?) ?? const [])
        _dtrEntry(Map<String, dynamic>.from(e as Map), updatedAt),
    ];

    final shiftDate = ars.isEmpty
        ? updatedAt
        : ars.map((a) => a.classDate).reduce((a, b) => a.isBefore(b) ? a : b);

    final subStatus = _s(j['submission_status'] ?? j['status']).toLowerCase();
    final isDisapproved =
        subStatus == 'disapproved' ||
        subStatus == 'rejected' ||
        dtrStatusValue.toLowerCase() == 'disapproved' ||
        dtrStatusValue.toLowerCase() == 'rejected' ||
        (_s(j['remarks']).toLowerCase().contains('disapprov') &&
            !_s(j['remarks']).toLowerCase().contains('resubmit'));

    final rejectionRemarks = isDisapproved
        ? (_s(j['submission_notes']).isNotEmpty
              ? _s(j['submission_notes'])
              : _s(j['remarks'], 'Returned for correction'))
        : null;

    // Disapproved reports are blocked from payroll; received wins over available;
    // neither means not available yet.
    final payrollStatus = isDisapproved
        ? PayrollStatus.disapproved
        : _b(j['payroll_received'])
        ? PayrollStatus.received
        : _b(j['payroll_availability'])
        ? PayrollStatus.available
        : PayrollStatus.notAvailable;

    final rawPeriodLabel = _s(j['periodLabel']);
    final normalizedPeriodLabel =
        rawPeriodLabel.toUpperCase().contains(' I') ||
            rawPeriodLabel.toUpperCase().contains(' II')
        ? rawPeriodLabel
        : _periodLabel(periodKey);

    return ReportItem(
      id: id,
      periodLabel: normalizedPeriodLabel,
      stage: isDisapproved ? PipelineStage.rejected : _pipelineStage(stageNo),
      dtrStage: dtrStage,
      dtrStatus: dtrStatusValue.isNotEmpty
          ? dtrStatusValue
          : dtrStageValue.startsWith('DTR-AP-STG-')
          ? 'pending'
          : null,
      updatedAt: updatedAt,
      rejectionRemarks: rejectionRemarks,
      professorName: _s(j['professorName']),
      professorId: _s(j['professorId']),
      department: _s(j['department'], '—'),
      position: _s(j['position'], '—'),
      shiftDate: shiftDate,
      reportNarrative: _s(j['remarks']),
      dtrTally: dtrHours,
      arTaskTally: ars.length,
      payrollStatus: payrollStatus,
      periodStart: periodStart,
      periodEnd: periodEnd,
    );
  }
}
