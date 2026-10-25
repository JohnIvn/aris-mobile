import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/ar_item.dart';
import '../models/report_item.dart';
import '../models/status.dart';
import '../services/ar_service.dart';
import '../services/auth_service.dart';

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

  /// Set once, where the app creates its [AuthService]:
  /// `ReportsStore().auth = authService;`
  AuthService? auth;

  List<ReportItem> _reports = const [];
  final Map<String, int> _stageNo = {};
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
  int stageOf(ReportItem r) => _stageNo[r.id] ?? 1;

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
      final base = dotenv.env['SERVER_URL'];
      if (base == null || base.isEmpty) {
        throw StateError('SERVER_URL is not set in .env');
      }
      final token = auth?.token;
      if (token == null) throw StateError('Not signed in');

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
        await auth?.signOut();
        throw Exception('Session expired. Please sign in again.');
      }
      if (res.statusCode != 200) {
        throw Exception('Server responded ${res.statusCode}');
      }

      final body = jsonDecode(res.body);
      final rows = _extractRows(body);
      debugPrint(
        '[ReportsStore] offset=${reset ? 0 : _offset} rows=${rows.length}',
      );

      final parsed = [
        for (final row in rows) _parse(Map<String, dynamic>.from(row as Map)),
      ];

      if (reset) {
        _reports = parsed;
        _offset = rows.length;
      } else {
        final known = _reports.map((r) => r.id).toSet();
        _reports = [..._reports, ...parsed.where((r) => !known.contains(r.id))];
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
    1 || 2 => PipelineStage.submitted,
    3 => PipelineStage.hr,
    _ => PipelineStage.completed,
  };

  String _hm(String t) => t.length >= 5 ? t.substring(0, 5) : t;

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
    final stageNo = _stageNumber(_s(j['stage'])).clamp(1, 4);
    _stageNo[id] = stageNo;

    final arTally = j['arTally'] as Map?;
    final entries = ((arTally?['entries'] as List?) ?? const [])
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

    final shiftDate = ars.isEmpty
        ? updatedAt
        : ars.map((a) => a.classDate).reduce((a, b) => a.isBefore(b) ? a : b);

    return ReportItem(
      id: id,
      periodLabel: _s(j['periodLabel']),
      stage: _pipelineStage(stageNo),
      updatedAt: updatedAt,
      professorName: _s(j['professorName']),
      professorId: _s(j['professorId']),
      department: _s(j['department'], '—'),
      position: _s(j['position'], '—'),
      shiftDate: shiftDate,
      reportNarrative: _s(j['remarks']),
      dtrTally: dtrHours,
      arTaskTally: ars.length,
      payrollStatus: PayrollStatus.notAvailable,
    );
  }
}
