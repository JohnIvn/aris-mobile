import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

enum UpdateStatus { idle, checking, available, downloading, installing, error }

/// Checks the latest GitHub release and installs its APK (Android only).
/// The repo must be public and the release must have an .apk asset.
///
/// Reads from .env:
///   GITHUB_USERNAME    = repo owner
///   GITHUB_REPOSITORY  = repo name only (not owner/repo)
class UpdateStore extends ChangeNotifier {
  UpdateStatus status = UpdateStatus.idle;
  String? currentVersion;
  String? latestVersion;
  String? apkUrl;
String? notes;
  int progress = 0;
  String? error;

  bool get available => status == UpdateStatus.available;

  void _set(UpdateStatus s, {String? err}) {
    status = s;
    error = err;
    notifyListeners();
  }

  Future<void> check() async {
    if (!Platform.isAndroid) return;
    if (status == UpdateStatus.checking ||
        status == UpdateStatus.downloading ||
        status == UpdateStatus.installing) {
      return;
    }

    final owner = dotenv.env['GITHUB_USERNAME']?.trim() ?? '';
    final repo = dotenv.env['GITHUB_REPOSITORY']?.trim() ?? '';
    if (owner.isEmpty || repo.isEmpty) {
      debugPrint(
        'Update check skipped: GITHUB_USERNAME/GITHUB_REPOSITORY not set.',
      );
      return;
    }

    _set(UpdateStatus.checking);

    try {
      final res = await http.get(
        Uri.parse('https://api.github.com/repos/$owner/$repo/releases/latest'),
        headers: {'Accept': 'application/vnd.github+json'},
      );
      if (res.statusCode != 200) {
        _set(UpdateStatus.idle);
        return;
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final remote = _clean(data['tag_name'] as String? ?? '');

      final assets = (data['assets'] as List? ?? const []);
      final apk = assets.cast<Map<String, dynamic>>().firstWhere(
        (a) => (a['name'] as String? ?? '').toLowerCase().endsWith('.apk'),
        orElse: () => const {},
      );
      final url = apk['browser_download_url'] as String?;

      currentVersion = (await PackageInfo.fromPlatform()).version;
      if (url == null || !_isNewer(remote, currentVersion!)) {
        _set(UpdateStatus.idle);
        return;
      }

      latestVersion = remote;
      apkUrl = url;
      notes = (data['body'] as String?)?.trim();
      _set(UpdateStatus.available);
    } catch (e) {
      debugPrint('Update check failed: $e');
      _set(
        UpdateStatus.idle,
      ); // Silent: a failed check shouldn't bother the user.
    }
  }

  void install() {
    final url = apkUrl;
    if (url == null) return;
    progress = 0;
    _set(UpdateStatus.downloading);

    OtaUpdate()
        .execute(url, destinationFilename: 'aris-$latestVersion.apk')
        .listen(
          (event) {
            switch (event.status) {
              case OtaStatus.DOWNLOADING:
                progress = int.tryParse(event.value ?? '') ?? progress;
                notifyListeners();
              case OtaStatus.INSTALLING:
              case OtaStatus.INSTALLATION_DONE:
                _set(UpdateStatus.installing);
              case OtaStatus.CANCELED:
                _set(UpdateStatus.available);
              default:
                _set(
                  UpdateStatus.error,
                  err: 'Update failed (${event.status.name}).',
                );
            }
          },
          onError: (Object e) =>
              _set(UpdateStatus.error, err: 'Update failed: $e'),
        );
  }

  /// "v1.2.0+3" -> "1.2.0"
  static String _clean(String v) =>
      v.replaceFirst(RegExp(r'^[vV]'), '').split('+').first.split('-').first;

  static bool _isNewer(String remote, String local) {
    final r = remote.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final l = local.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    for (var i = 0; i < 3; i++) {
      final a = i < r.length ? r[i] : 0;
      final b = i < l.length ? l[i] : 0;
      if (a != b) return a > b;
    }
    return false;
  }
}
