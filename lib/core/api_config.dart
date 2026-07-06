import 'package:flutter/foundation.dart';

/// Global API configuration — mirrors `luxora-fullweb` axios `baseURL: ${origin}/api`.
///
/// Replace `[INSERT_YOUR_IP_HERE]` with your machine’s LAN IP from `ipconfig`
/// (e.g. `192.168.1.10`) so a physical device on the same Wi‑Fi can reach Laravel.
class ApiConfig {
  ApiConfig._();

  static String get baseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) {
      return fromEnv;
    }
    
    if (kIsWeb) {
      return 'http://localhost:8000/api';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8000/api';
      default:
        return 'http://localhost:8000/api';
    }
  }

  /// Same as [baseUrl] (alias for older call sites).
  static String get apiBaseUrl => baseUrl;

  /// Laravel app origin without `/api` — use to resolve relative media paths (`/storage/...`).
  static String get origin {
    var o = baseUrl.trim();
    if (o.endsWith('/api')) {
      o = o.substring(0, o.length - 4);
    } else if (o.endsWith('/api/')) {
      o = o.substring(0, o.length - 5);
    }
    while (o.endsWith('/')) {
      o = o.substring(0, o.length - 1);
    }
    return o;
  }
}
