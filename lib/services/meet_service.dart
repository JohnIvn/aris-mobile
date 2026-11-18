import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/meet_item.dart';
import 'app_env.dart';
import 'auth_service.dart';

/// Fetches `GET {SERVER_URL}/meetings/summaries` (optionally with
/// `?email=<prof email>`) and returns a list of [MeetItem] objects,
/// mirroring what the aris-app Summaries page shows.
class MeetService extends ChangeNotifier {
  static final MeetService _instance = MeetService._();
  factory MeetService() => _instance;
  MeetService._();

  /// Must be wired before first use (same pattern as ReportsStore.auth).
  AuthService? auth;

  List<MeetItem> _items = const [];
  bool _loading = false;
  String? _error;

  List<MeetItem> get items => _items;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final base = AppEnv.serverUrl;
      if (base.isEmpty) throw StateError('SERVER_URL is not set in .env');

      final a = auth;
      final token = a?.token;
      if (a == null || token == null || token.isEmpty) {
        throw StateError('Not signed in');
      }

      final email = a.user?.email ?? '';
      final uri = Uri.parse(
        '${base.replaceAll(RegExp(r'/+$'), '')}/meetings/summaries',
      ).replace(
        queryParameters: email.isNotEmpty ? {'email': email} : null,
      );

      final res = await http
          .get(uri, headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          })
          .timeout(const Duration(seconds: 20));

      if (res.statusCode == 401) {
        await a.signOut();
        throw Exception('Session expired. Please sign in again.');
      }
      if (res.statusCode != 200) {
        throw Exception('Server responded ${res.statusCode}');
      }

      final body = jsonDecode(res.body);
      final rows = _extract(body);
      _items = [
        for (final r in rows)
          MeetItem.fromJson(Map<String, dynamic>.from(r as Map)),
      ];
    } catch (e, st) {
      debugPrint('[MeetService] $e\n$st');
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  List _extract(Object? body) {
    if (body is List) return body;
    if (body is Map) {
      for (final key in const ['data', 'summaries', 'items', 'results']) {
        final v = body[key];
        if (v is List) return v;
      }
    }
    return const [];
  }
}
