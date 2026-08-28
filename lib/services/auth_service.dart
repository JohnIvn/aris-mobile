import 'package:flutter/foundation.dart';

enum AuthStatus { unauthenticated, authenticating, authenticated }

class AuthUser {
  final String name;
  final String email;
  final String provider;

  const AuthUser({
    required this.name,
    required this.email,
    required this.provider,
  });
}

/// Stub auth layer. `signInWithOAuth` currently just fakes a delay
/// and logs a dummy user in — swap its body for a real call once
/// you've picked a provider (e.g. the `google_sign_in` package for
/// native Google OAuth, or launching a web OAuth flow via
/// `flutter_web_auth_2` / an in-app browser to your redirect URI).
/// Nothing else in the app needs to change: screens only read
/// `status` / `user` from this class via [AuthScope].
class AuthService extends ChangeNotifier {
  AuthStatus _status = AuthStatus.unauthenticated;
  AuthUser? _user;
  String? _error;

  AuthStatus get status => _status;
  AuthUser? get user => _user;
  String? get error => _error;

  Future<void> signInWithOAuth() async {
    _status = AuthStatus.authenticating;
    _error = null;
    notifyListeners();

    try {
      // TODO: replace with a real OAuth call (see class doc above).
      await Future.delayed(const Duration(milliseconds: 900));
      _user = const AuthUser(
        name: 'Matthew',
        email: 'matthew@example.edu',
        provider: 'OAuth',
      );
      _status = AuthStatus.authenticated;
    } catch (_) {
      _status = AuthStatus.unauthenticated;
      _error = 'Sign-in failed. Please try again.';
    }
    notifyListeners();
  }

  void signOut() {
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
