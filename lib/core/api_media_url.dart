import 'api_config.dart';

/// Resolves Laravel image paths for use in [Image.network].
///
/// - Relative paths like `/storage/foo.jpg` are prefixed with [ApiConfig.origin].
/// - Absolute URLs on `localhost` / `127.0.0.1` are rewritten to [ApiConfig.origin]
///   (Android emulator uses `10.0.2.2` while Laravel often returns `127.0.0.1`).
/// - Absolute **http** URLs whose path starts with `/storage/` are rewritten to
///   [ApiConfig.origin] (Laravel public disk). Explore often uses https CDN URLs,
///   which are left as-is.
class ApiMediaUrl {
  ApiMediaUrl._();

  static String? resolve(String? path) {
    if (path == null || path.trim().isEmpty) {
      return null;
    }
    final p = path.trim();
    if (p.startsWith('http://') || p.startsWith('https://')) {
      return _rewriteAbsoluteMediaUrl(p);
    }
    final origin = ApiConfig.origin;
    final suffix = p.startsWith('/') ? p : '/$p';
    return '$origin$suffix';
  }

  static String _rewriteAbsoluteMediaUrl(String url) {
    final parsed = Uri.tryParse(url);
    if (parsed == null) return url;
    final api = Uri.parse(ApiConfig.origin);
    final host = parsed.host.toLowerCase();
    final isLoopback = host == 'localhost' || host == '127.0.0.1';
    final isLaravelStorage = parsed.path.startsWith('/storage/');
    // Local Laravel serves storage over http; keep https URLs unchanged (e.g. CDNs).
    final rewriteStorageToApiHost =
        isLaravelStorage && parsed.scheme == 'http';

    if (isLoopback || rewriteStorageToApiHost) {
      // Always keep the media URL's port (e.g. :8000). Using `port: null` when the
      // API origin omits an explicit port would default to 80 and break Laravel dev.
      return parsed.replace(
        scheme: api.scheme,
        host: api.host,
        port: parsed.port,
      ).toString();
    }
    return url;
  }
}
