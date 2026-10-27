import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/notification_item.dart';

class NotificationException implements Exception {
  final String message;
  final int? statusCode;
  NotificationException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class NotificationService {
  NotificationService({required this.tokenProvider});

  final String? Function() tokenProvider;

  static const _listPath = '/notifications';
  static const _readAllPath = '/notifications/read-all';
  static String _readPath(String id) => '/notifications/$id/read';
  static String _itemPath(String id) => '/notifications/$id';
  static const _pageSize = 50;

  static String get _baseUrl => dotenv.env['SERVER_URL'] ?? '';

  Map<String, String> _headers({bool json = false}) {
    final token = tokenProvider();
    if (_baseUrl.isEmpty) {
      throw NotificationException('Missing SERVER_URL in .env');
    }
    if (token == null || token.isEmpty) {
      throw NotificationException('Not signed in', statusCode: 401);
    }
    return {
      if (json) 'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<NotificationItem>> fetch({int offset = 0}) async {
    final decoded = await _send(
      () => http.get(
        Uri.parse('$_baseUrl$_listPath/mobile?offset=$offset&limit=$_pageSize'),
        headers: _headers(),
      ),
    );

    final list = _extractList(decoded);
    if (list == null) {
      throw NotificationException(
        kDebugMode
            ? 'No list in response: ${decoded is Map ? decoded.keys.toList() : decoded.runtimeType}'
            : 'Invalid server response',
      );
    }

    return list
        .whereType<Map>()
        .map((e) => NotificationItem.fromJson(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> markRead(String id) async {
    await _send(
      () => http.patch(
        Uri.parse('$_baseUrl${_readPath(id)}'),
        headers: _headers(),
      ),
    );
  }

  Future<void> markAllRead() async {
    await _send(
      () =>
          http.patch(Uri.parse('$_baseUrl$_readAllPath'), headers: _headers()),
    );
  }

  Future<void> delete(String id) async {
    await _send(
      () => http.delete(
        Uri.parse('$_baseUrl${_itemPath(id)}'),
        headers: _headers(),
      ),
    );
  }

  /// Returns the first list found in the body, at any depth, under any key.
  List<dynamic>? _extractList(Object? decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map) {
      for (final v in decoded.values) {
        final found = _extractList(v);
        if (found != null) return found;
      }
    }
    return null;
  }

  Future<Object?> _send(Future<http.Response> Function() request) async {
    try {
      final res = await request().timeout(const Duration(seconds: 20));

      if (kDebugMode) {
        debugPrint(
          '[Notifications] ${res.request?.method} ${res.request?.url} '
          '-> ${res.statusCode}\n${res.body}',
        );
      }

      Object? decoded;
      if (res.body.trim().isNotEmpty) {
        try {
          decoded = jsonDecode(res.body);
        } on FormatException {
          throw NotificationException(
            kDebugMode
                ? 'Non-JSON response (HTTP ${res.statusCode}): '
                      '${res.body.substring(0, res.body.length.clamp(0, 120))}'
                : 'Invalid server response',
            statusCode: res.statusCode,
          );
        }
      }

      // Your handlers return {status, ok, code, error, data} with HTTP 200.
      int? bodyStatus;
      if (decoded is Map) {
        if (decoded['code'] is int) {
          bodyStatus = decoded['code'] as int;
        } else if (decoded['statusCode'] is int) {
          bodyStatus = decoded['statusCode'] as int;
        } else if (decoded['ok'] == false) {
          bodyStatus = res.statusCode == 200 ? 500 : res.statusCode;
        }
      }
      final status = bodyStatus ?? res.statusCode;

      if (status < 200 || status >= 300) {
        final msg = decoded is Map
            ? (decoded['error'] ?? decoded['message'] ?? 'Request failed')
            : 'Request failed (HTTP $status)';
        throw NotificationException(msg.toString(), statusCode: status);
      }
      return decoded;
    } on SocketException {
      throw NotificationException('No internet connection');
    } on TimeoutException {
      throw NotificationException('Request timed out');
    } on http.ClientException catch (e) {
      throw NotificationException('Network error: ${e.message}');
    }
  }
}
