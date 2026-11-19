import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/attendance_transaction.dart';
import '../models/dtr_entry.dart';
import '../services/app_env.dart';
import '../services/auth_service.dart';

/// Fetches attendance_transactions from `GET /biometrics/transactions`
/// for the signed-in user (filtered by their `employee_id` / `emp_code`),
/// then groups punches by calendar date to produce [DtrEntry] rows — the same
/// logic used by DtrSubmitPage in aris-app.
///
/// Usage:
/// ```dart
/// final service = DtrService();
/// service.auth = authService;
/// final entries = await service.fetchEntries(
///   startDate: '2026-11-01',
///   endDate: '2026-11-30',
/// );
/// ```
class DtrService {
  static final DtrService _instance = DtrService._();
  factory DtrService() => _instance;
  DtrService._();

  static const int _pageSize = 2000;
  static const int _maxPages = 50;

  /// Must be set before any fetch (wired in main.dart alongside ReportsStore).
  AuthService? auth;

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  /// Returns DTR entries for [startDate]..[endDate] (inclusive, `yyyy-MM-dd`).
  /// Throws on network / auth errors.
  Future<List<DtrEntry>> fetchEntries({
    required String startDate,
    required String endDate,
  }) async {
    // The server identifies the user from the Bearer token and automatically
    // restricts transactions to their `biometrics_emp_id` via `user_id_biometrics`,
    // matching the behavior of aris-app (emp_code: "").
    final punches = await _fetchAllPunches(
      startDate: startDate,
      endDate: endDate,
    );
    return _computeEntries(punches, startDate: startDate, endDate: endDate);
  }

  /// Discovers all YYYY-MM months that have biometric punch records in
  /// `attendance_transactions` plus the current month, matching aris-app's
  /// `loadAvailableMonths()`.
  Future<List<String>> fetchAvailableMonths() async {
    final now = DateTime.now();
    final startDate = '${now.year - 1}-01-01';
    final endDate = '${now.year + 1}-12-31';

    final monthSet = <String>{};
    final currentYm =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
    monthSet.add(currentYm);

    try {
      final punches = await _fetchAllPunches(
        startDate: startDate,
        endDate: endDate,
      );

      for (final p in punches) {
        final ym =
            '${p.punchTime.year.toString().padLeft(4, '0')}-${p.punchTime.month.toString().padLeft(2, '0')}';
        monthSet.add(ym);
      }
    } catch (e) {
      debugPrint('[DtrService] fetchAvailableMonths error: $e');
    }

    final months = monthSet.toList()..sort();
    return months;
  }

  // -------------------------------------------------------------------------
  // Private helpers
  // -------------------------------------------------------------------------

  String _token() {
    final token = auth?.token;
    if (token == null || token.isEmpty) throw Exception('Not signed in.');
    return token;
  }

  String get _base =>
      AppEnv.serverUrl.replaceAll(RegExp(r'/+$'), '');

  /// Pages through /biometrics/transactions until all punches are collected.
  Future<List<AttendanceTransaction>> _fetchAllPunches({
    required String startDate,
    required String endDate,
  }) async {
    final token = _token();
    final all = <AttendanceTransaction>[];

    for (var page = 1; page <= _maxPages; page++) {
      final uri = Uri.parse('$_base/biometrics/transactions').replace(
        queryParameters: {
          'page': '$page',
          'limit': '$_pageSize',
          'emp_code': '',
          'start_date': startDate,
          'end_date': endDate,
        },
      );

      final res = await http
          .get(uri, headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          })
          .timeout(const Duration(seconds: 20));

      if (res.statusCode == 401) {
        await auth?.signOut();
        throw Exception('Session expired. Please sign in again.');
      }
      if (res.statusCode != 200) {
        throw Exception('Server responded ${res.statusCode}');
      }

      final body = jsonDecode(res.body);

      // Guard against API-level errors
      if (body is Map &&
          (body['ok'] == false || body['status'] == 'failure')) {
        throw Exception(
          'Server error: ${body['error'] ?? body['message'] ?? 'unknown'}',
        );
      }

      final batch = _extractList(body);
      all.addAll(batch.map(
        (e) => AttendanceTransaction.fromJson(Map<String, dynamic>.from(e as Map)),
      ));

      debugPrint('[DtrService] page=$page fetched=${batch.length}');

      if (batch.length < _pageSize) break; // last page
    }

    return all;
  }

  List _extractList(Object? body) {
    if (body is List) return body;
    if (body is Map) {
      for (final key in const ['data', 'records', 'items', 'results']) {
        final v = body[key];
        if (v is List) return v;
      }
    }
    return const [];
  }

  // -------------------------------------------------------------------------
  // DTR computation (mirrors DtrSubmitPage logic from aris-app)
  // -------------------------------------------------------------------------

  /// Groups [punches] by date and determines time-in, time-out, and status.
  ///
  /// Rules (same as the aris-app professor DTR page):
  ///   • First punch of the day  → time_in
  ///   • Last punch of the day   → time_out (if different from first)
  ///   • Has time_in & time_out  → present (or late if time_in > 08:30)
  ///   • Has only time_in         → missing punch
  ///   • No punches              → absent
  ///
  /// Days that fall on a weekend are skipped (no DTR row generated).
  List<DtrEntry> _computeEntries(
    List<AttendanceTransaction> punches, {
    required String startDate,
    required String endDate,
  }) {
    final start = DateTime.parse(startDate);
    final end = DateTime.parse(endDate);

    // Group punches by date string (yyyy-MM-dd) in local time
    final byDate = <String, List<AttendanceTransaction>>{};
    for (final p in punches) {
      final key = _dateKey(p.punchTime);
      byDate.putIfAbsent(key, () => []).add(p);
    }

    final entries = <DtrEntry>[];

    for (var d = start;
        !d.isAfter(end);
        d = d.add(const Duration(days: 1))) {
      // Skip weekends
      if (d.weekday == DateTime.saturday || d.weekday == DateTime.sunday) {
        continue;
      }

      final key = _dateKey(d);
      final dayPunches = byDate[key] ?? [];

      if (dayPunches.isEmpty) {
        // Future dates without punches yet — don't mark as absent
        if (d.isAfter(DateTime.now())) continue;

        entries.add(DtrEntry(
          date: d,
          timeIn: null,
          timeOut: null,
          status: DtrDayStatus.absent,
        ));
        continue;
      }

      // Sort chronologically
      dayPunches.sort((a, b) => a.punchTime.compareTo(b.punchTime));

      // Group the day's punches into in/out sessions.
      // Matches the backend punch rule: open punch -> time out; otherwise -> time in.
      // (Terminal buttons are not toggled by users, so taps alternate chronologically).
      final sessions = <_PunchSession>[];
      DateTime? currentIn;

      for (final p in dayPunches) {
        if (currentIn == null) {
          currentIn = p.punchTime;
        } else {
          sessions.add(_PunchSession(timeIn: currentIn, timeOut: p.punchTime));
          currentIn = null;
        }
      }

      if (currentIn != null) {
        sessions.add(_PunchSession(timeIn: currentIn, timeOut: null));
      }

      for (final s in sessions) {
        final timeInStr = s.timeIn != null ? _formatTime(s.timeIn!) : null;
        final timeOutStr = s.timeOut != null ? _formatTime(s.timeOut!) : null;

        DtrDayStatus status;
        if (s.timeIn == null || s.timeOut == null) {
          status = DtrDayStatus.missing;
        } else {
          final lateThreshold =
              DateTime(s.timeIn!.year, s.timeIn!.month, s.timeIn!.day, 8, 30);
          status = (s.timeIn!.hour < 12 && s.timeIn!.isAfter(lateThreshold))
              ? DtrDayStatus.late
              : DtrDayStatus.present;
        }

        entries.add(DtrEntry(
          date: d,
          timeIn: timeInStr,
          timeOut: timeOutStr,
          status: status,
        ));
      }
    }

    // Oldest first (same order as records_screen expects)
    entries.sort((a, b) => a.date.compareTo(b.date));
    return entries;
  }

  /// Formats a [DateTime] as `h:mm AM/PM` (e.g. `8:05 AM`, `1:30 PM`).
  String _formatTime(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute;
    final h12 = h % 12 == 0 ? 12 : h % 12;
    final ampm = h < 12 ? 'AM' : 'PM';
    return '$h12:${m.toString().padLeft(2, '0')} $ampm';
  }

  /// Returns `yyyy-MM-dd` for a [DateTime] in local time.
  String _dateKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';
}

class _PunchSession {
  final DateTime? timeIn;
  final DateTime? timeOut;

  const _PunchSession({this.timeIn, this.timeOut});
}
