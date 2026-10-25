import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

enum AuthStatus { unauthenticated, authenticating, authenticated }

class AuthUser {
  final String id;
  final String role; // 'staff' | 'professor'
  final String name;
  final String email;
  final String provider;
  final String employeeId;
  final String username;
  final String? avatarUrl;
  final String? position;
  final String? department;

  /// Full backend payload (middlename, birthday, age, gender, timestamps...).
  final Map<String, dynamic> raw;

  const AuthUser({
    required this.id,
    required this.role,
    required this.name,
    required this.email,
    required this.provider,
    required this.employeeId,
    required this.username,
    this.avatarUrl,
    this.position,
    this.department,
    required this.raw,
  });

  factory AuthUser.fromJson(Map<String, dynamic> j) => AuthUser(
    id: j['id'] as String,
    role: j['role'] as String,
    name: '${j['firstname'] ?? ''} ${j['lastname'] ?? ''}'.trim(),
    email: j['email'] as String,
    provider: (j['provider'] ?? 'google') as String,
    employeeId: j['employee_id'] as String,
    username: j['username'] as String,
    avatarUrl: j['avatar_url'] as String?,
    position: j['position'] as String?,
    department: j['department'] as String?,
    raw: j,
  );
}

class AuthException implements Exception {
  final String message;
  final int? statusCode;
  final bool cancelled;
  AuthException(this.message, {this.statusCode, this.cancelled = false});

  @override
  String toString() => message;
}

class AuthService extends ChangeNotifier {
  // flutter run --dart-define=SERVER_URL=... \
  //   --dart-define=ANDROID_GOOGLE_CLIENT_ID=... \
  //   --dart-define=IOS_GOOGLE_CLIENT_ID=...
  static String get _webClientId => dotenv.env['WEB_GOOGLE_CLIENT_ID'] ?? '';

  static String get _baseUrl => dotenv.env['SERVER_URL'] ?? '';

  // static String get _androidClientId =>
  //     dotenv.env['ANDROID_GOOGLE_CLIENT_ID'] ?? '';

  static String get _iosClientId => dotenv.env['IOS_GOOGLE_CLIENT_ID'] ?? '';

  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  final _storage = const FlutterSecureStorage();
  Future<void>? _googleInit;
  String? _pendingIdToken; // reused by sign-up after a 404 on sign-in

  AuthStatus _status = AuthStatus.unauthenticated;
  AuthUser? _user;
  String? _token;
  String? _error;
  bool _needsSignUp = false;

  AuthStatus get status => _status;
  AuthUser? get user => _user;
  String? get token => _token;
  String? get error => _error;

  /// True after a Google sign-in found no account. Show the sign-up form and
  /// call [signUpWithGoogle].
  bool get needsSignUp => _needsSignUp;

  String get _platform => Platform.isIOS ? 'ios' : 'android';

  // ---------------------------------------------------------------- public

  /// Call once at app start, before showing the login screen.
  Future<void> restoreSession() async {
    final token = await _storage.read(key: _tokenKey);
    final raw = await _storage.read(key: _userKey);

    if (token == null || raw == null || _isExpired(token)) {
      await _clear();
    } else {
      _token = token;
      _user = AuthUser.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
      _status = AuthStatus.authenticated;
    }
    notifyListeners();
  }

  Future<void> signInWithOAuth() async {
    _status = AuthStatus.authenticating;
    _error = null;
    _needsSignUp = false;
    notifyListeners();

    try {
      if (_baseUrl.isEmpty || _webClientId.isEmpty) {
        throw AuthException(
          'Missing SERVER_URL / WEB_GOOGLE_CLIENT_ID in .env',
        );
      }

      final idToken = await _getIdToken();
      _pendingIdToken = idToken;

      final payload = {'id_token': idToken, 'platform': _platform};

      final data = await _post('/auth/google/mobile/signin', payload);

      _pendingIdToken = null;

      await _persist(data);

      debugPrint('[OAuth] Sign-in successful!');
    } on AuthException catch (e, st) {
      debugPrint('[OAuth] AuthException: ${e.message}');
      debugPrint('[OAuth] Status code: ${e.statusCode}');
      debugPrint('[OAuth] Cancelled: ${e.cancelled}');
      debugPrint('[OAuth] Stack trace: $st');

      _pendingIdToken = null;
      _status = AuthStatus.unauthenticated;

      if (e.statusCode == 404) {
        _needsSignUp = true;
        debugPrint('[OAuth] Account not found. Sign-up required.');
      } else if (!e.cancelled) {
        _error = e.message;
      }
    } catch (e, st) {
      debugPrint('[OAuth] Unexpected error: $e');
      debugPrint('[OAuth] Stack trace:\n$st');

      _pendingIdToken = null;
      _status = AuthStatus.unauthenticated;
      _error = kDebugMode
          ? 'Sign-in failed: $e'
          : 'Sign-in failed. Please try again.';
    }

    debugPrint('[OAuth] Final status: $_status');
    debugPrint('[OAuth] Error: $_error');

    notifyListeners();
  }

  // THIS WONT BE USED
  Future<void> signUpWithGoogle({
    required String role, // 'staff' | 'professor'
    required String employeeId,
    String? username,
    String? middlename,
    String? birthday, // yyyy-MM-dd
    String? gender,
    String? position,
    String? department,
  }) async {
    _status = AuthStatus.authenticating;
    _error = null;
    notifyListeners();

    try {
      final idToken = _pendingIdToken ?? await _getIdToken();
      _pendingIdToken = null;

      final data = await _post('/auth/google/mobile/signup', {
        'id_token': idToken,
        'platform': _platform,
        'role': role,
        'employee_id': employeeId,
        'username': ?username,
        'middlename': ?middlename,
        'birthday': ?birthday,
        'gender': ?gender,
        'position': ?position,
        'department': ?department,
      });

      _needsSignUp = false;
      await _persist(data);
    } on AuthException catch (e) {
      _status = AuthStatus.unauthenticated;
      if (!e.cancelled) _error = e.message;
    } catch (e, st) {
      debugPrint('signUp error: $e\n$st');
      _status = AuthStatus.unauthenticated;
      _error = kDebugMode
          ? 'Sign-up failed: $e'
          : 'Sign-up failed. Please try again.';
    }
    notifyListeners();
  }

  Future<void> signOut() async {
    try {
      await _ensureGoogleInit();
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    await _clear();
    notifyListeners();
  }

  // --------------------------------------------------------------- private

  Future<void> _ensureGoogleInit() {
    return _googleInit ??= GoogleSignIn.instance
        .initialize(
          clientId: Platform.isIOS ? _iosClientId : null,
          serverClientId: _webClientId,
        )
        .catchError((Object e) {
          _googleInit = null;
          throw e;
        });
  }

  Future<String> _getIdToken() async {
    try {
      await _ensureGoogleInit();
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw AuthException('Google did not return an ID token');
      }
      return idToken;
    } on GoogleSignInException catch (e) {
      debugPrint(
        '[OAuth] GoogleSignInException code=${e.code} description=${e.description} details=${e.details}',
      );
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw AuthException(
          'Sign-in cancelled (${e.description ?? 'no details'})',
          cancelled: true,
        );
      }
      throw AuthException(
        'Google sign-in failed: ${e.description ?? e.code.name}',
      );
    }
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_baseUrl$path'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));

      if (kDebugMode) {
        debugPrint('POST $path -> ${res.statusCode}\n${res.body}');
      }

      final decoded = jsonDecode(res.body);
      if (decoded is! Map) {
        throw AuthException(
          'Invalid server response',
          statusCode: res.statusCode,
        );
      }
      final json = Map<String, dynamic>.from(decoded);

      // Handlers may put the real status in the body while HTTP stays 200
      final bodyStatus = json['statusCode'] is int
          ? json['statusCode'] as int
          : null;
      final status = bodyStatus ?? res.statusCode;

      // Payload may be wrapped in `data` or returned at the top level.
      final Object? payload = json['data'] is Map
          ? json['data']
          : (json.containsKey('token') && json.containsKey('user')
                ? json
                : null);

      if (status < 200 || status >= 300 || payload == null) {
        throw AuthException(
          (json['message'] ?? json['error'] ?? 'Request failed').toString(),
          statusCode: status,
        );
      }

      return Map<String, dynamic>.from(payload as Map);
    } on SocketException {
      throw AuthException('No internet connection');
    } on TimeoutException {
      throw AuthException('Request timed out');
    } on http.ClientException catch (e) {
      throw AuthException('Network error: ${e.message}');
    } on FormatException {
      throw AuthException('Invalid server response');
    }
  }

  Future<void> _persist(Map<String, dynamic> data) async {
    final userJson = Map<String, dynamic>.from(data['user'] as Map);

    _token = data['token'] as String;
    _user = AuthUser.fromJson(userJson);
    _status = AuthStatus.authenticated;

    await _storage.write(key: _tokenKey, value: _token);
    await _storage.write(key: _userKey, value: jsonEncode(userJson));
  }

  Future<void> _clear() async {
    _token = null;
    _user = null;
    _error = null;
    _needsSignUp = false;
    _pendingIdToken = null;
    _status = AuthStatus.unauthenticated;
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }

  bool _isExpired(String token) {
    try {
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(token.split('.')[1])),
      );
      final exp = (jsonDecode(payload) as Map)['exp'] as num?;
      if (exp == null) return false;
      return DateTime.now().millisecondsSinceEpoch ~/ 1000 >= exp - 30;
    } catch (_) {
      return true;
    }
  }
}
