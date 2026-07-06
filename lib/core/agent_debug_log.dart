import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

class AgentDebugLog {
  AgentDebugLog._();

  static const String _sessionId = 'c45113';
  static const String _ingestUrl =
      'http://127.0.0.1:7625/ingest/77b65d96-e3de-4703-bf08-bc70409655c4';

  static final HttpClient _client = HttpClient()
    ..connectionTimeout = const Duration(milliseconds: 800);

  static void log({
    required String runId,
    required String hypothesisId,
    required String location,
    required String message,
    Map<String, Object?> data = const <String, Object?>{},
  }) {
    if (kIsWeb) return;
    try {
      final payload = <String, Object?>{
        'sessionId': _sessionId,
        'runId': runId,
        'hypothesisId': hypothesisId,
        'location': location,
        'message': message,
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      // Always mirror to device console so we have runtime evidence even when
      // port-forwarding/ingest isn't configured (e.g. wireless runs).
      debugPrint('[AgentDebugLog] ${jsonEncode(payload)}');

      // Phone/device runs won't write to the dev machine filesystem; POST to the ingest server instead.
      // Fire-and-forget: never block UI threads.
      // ignore: discarded_futures
      _client
          .postUrl(Uri.parse(_ingestUrl))
          .then((req) {
            req.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
            req.headers.set('X-Debug-Session-Id', _sessionId);
            req.add(utf8.encode(jsonEncode(payload)));
            return req.close();
          })
          .then((res) => res.drain<void>())
          .catchError((_) {});
    } catch (_) {
      // Never crash the app for logging.
    }
  }
}
