import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_config.dart';
import 'auth_storage.dart';
import 'session_navigation.dart';

/// Central Dio instance — same behavior as `luxora-frontend/src/services/api.js`:
/// - `Accept: application/json`, `X-Requested-With: XMLHttpRequest`
/// - `Authorization: Bearer <token>` when present
/// - FormData: do not force `Content-Type` (let Dio set multipart boundary)
/// - Logs full responses for debugging
class ApiClient {
  ApiClient._();

  static Dio? _dio;

  static Dio get dio {
    return _dio ??= _create();
  }

  static const Set<String> _publicPaths = <String>{
    '/login',
    '/register',
  };

  static const List<String> _protectedPrefixes = <String>[
    '/logout',
    '/user',
    '/landmarks',
    '/scan',
    '/translations',
    '/chat',
    '/albums',
    '/favorites',
    '/admin',
  ];

  static Dio _create() {
    final client = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: <String, dynamic>{
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
        },
      ),
    );

    client.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          options.headers['Accept'] = 'application/json';
          options.headers['X-Requested-With'] = 'XMLHttpRequest';

          if (options.data is FormData) {
            options.headers.remove('Content-Type');
          } else if (options.method != 'GET' &&
              options.data != null &&
              options.headers['Content-Type'] == null) {
            options.headers['Content-Type'] = 'application/json';
          }

          final token = await AuthStorage.getToken();
          if (!_publicPaths.contains(options.path)) {
            if (token == null || token.isEmpty) {
              if (_isProtectedPath(options.path)) {
                handler.reject(
                  DioException(
                    requestOptions: options,
                    response: Response<dynamic>(
                      requestOptions: options,
                      statusCode: 401,
                      data: <String, dynamic>{
                        'message': 'Authentication required. Please login first.',
                      },
                    ),
                    type: DioExceptionType.badResponse,
                  ),
                );
                return;
              }
            } else {
              options.headers['Authorization'] = 'Bearer $token';
            }
          } else if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            debugPrint(
              '[API] ${response.statusCode} ${response.requestOptions.uri}',
            );
            debugPrint('[API] response: ${response.data}');
          }
          handler.next(response);
        },
        onError: (error, handler) async {
          if (kDebugMode) {
            final r = error.response;
            debugPrint(
              '[API] ERROR ${error.requestOptions.uri} '
              'status=${r?.statusCode} type=${error.type}',
            );
            debugPrint('[API] error body: ${r?.data}');
          }
          if (error.response?.statusCode == 401) {
            await AuthStorage.clearToken();
            SessionNavigation.redirectToLogin();
          }
          handler.next(error);
        },
      ),
    );

    return client;
  }

  static bool _isProtectedPath(String path) {
    for (final prefix in _protectedPrefixes) {
      if (path == prefix || path.startsWith('$prefix/')) {
        return true;
      }
    }
    return false;
  }
}
