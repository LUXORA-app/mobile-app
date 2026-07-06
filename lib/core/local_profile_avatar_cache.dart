import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'agent_debug_log.dart';

/// Persists the last successfully uploaded profile photo to app storage
/// so Settings (and Profile) can show it even when the server URL returns 403.
class LocalProfileAvatarCache {
  LocalProfileAvatarCache._();

  static const String _prefsKeyPath = 'profile_local_avatar_path_v1';
  static const String _prefsKeyServerUrl = 'profile_local_avatar_server_url_v1';

  static Future<String?> getPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefsKeyPath);
  }

  /// Copies [source] into app documents and stores its path in prefs.
  static Future<String?> saveFromPick(File source) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final destDir = Directory(p.join(dir.path, 'profile_avatar_cache'));
      if (!await destDir.exists()) {
        await destDir.create(recursive: true);
      }
      final destPath = p.join(destDir.path, 'avatar.jpg');
      await source.copy(destPath);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKeyPath, destPath);

      // #region agent log
      AgentDebugLog.log(
        runId: 'pre-fix',
        hypothesisId: 'H',
        location: 'local_profile_avatar_cache.dart:saveFromPick',
        message: 'Saved local avatar copy',
        data: <String, Object?>{'destPath': destPath},
      );
      // #endregion

      return destPath;
    } catch (e) {
      // #region agent log
      AgentDebugLog.log(
        runId: 'pre-fix',
        hypothesisId: 'H',
        location: 'local_profile_avatar_cache.dart:saveFromPick:error',
        message: 'Failed to save local avatar copy',
        data: <String, Object?>{'error': e.toString()},
      );
      // #endregion
      return null;
    }
  }

  static Future<void> rememberServerAvatarUrl(String? url) async {
    final prefs = await SharedPreferences.getInstance();
    if (url == null || url.isEmpty) {
      await prefs.remove(_prefsKeyServerUrl);
      return;
    }
    await prefs.setString(_prefsKeyServerUrl, url);
  }

  /// Clears cached local file if server avatar URL changed (new upload elsewhere).
  static Future<void> reconcileWithServerAvatarUrl(String? resolvedServerUrl) async {
    final prefs = await SharedPreferences.getInstance();
    final prev = prefs.getString(_prefsKeyServerUrl);
    if (resolvedServerUrl == null || resolvedServerUrl.isEmpty) return;
    if (prev != null && prev.isNotEmpty && prev != resolvedServerUrl) {
      final path = prefs.getString(_prefsKeyPath);
      if (path != null && path.isNotEmpty) {
        try {
          await File(path).delete();
        } catch (_) {}
      }
      await prefs.remove(_prefsKeyPath);
    }
    await prefs.setString(_prefsKeyServerUrl, resolvedServerUrl);
  }
}
