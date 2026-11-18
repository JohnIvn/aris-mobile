import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEnv {
  static String get serverUrl {
    const v = String.fromEnvironment('SERVER_URL');
    if (v.isNotEmpty) return _clean(v);
    if (dotenv.isInitialized) {
      return _clean(dotenv.env['SERVER_URL'] ?? '');
    }
    return '';
  }

  static String get webGoogleClientId {
    const v = String.fromEnvironment('WEB_GOOGLE_CLIENT_ID');
    if (v.isNotEmpty) return _clean(v);
    if (dotenv.isInitialized) {
      return _clean(dotenv.env['WEB_GOOGLE_CLIENT_ID'] ?? '');
    }
    return '';
  }

  static String get iosGoogleClientId {
    const v = String.fromEnvironment('IOS_GOOGLE_CLIENT_ID');
    if (v.isNotEmpty) return _clean(v);
    if (dotenv.isInitialized) {
      return _clean(dotenv.env['IOS_GOOGLE_CLIENT_ID'] ?? '');
    }
    return '';
  }

  static String get githubUsername {
    const v = String.fromEnvironment('GITHUB_USERNAME');
    if (v.isNotEmpty) return _clean(v);
    if (dotenv.isInitialized) {
      return _clean(dotenv.env['GITHUB_USERNAME'] ?? '');
    }
    return '';
  }

  static String get githubRepository {
    const v = String.fromEnvironment('GITHUB_REPOSITORY');
    if (v.isNotEmpty) return _clean(v);
    if (dotenv.isInitialized) {
      return _clean(dotenv.env['GITHUB_REPOSITORY'] ?? '');
    }
    return '';
  }

  static String _clean(String s) {
    return s.trim().replaceAll("'", '').replaceAll('"', '');
  }
}
