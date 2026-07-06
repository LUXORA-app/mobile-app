import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/api_config.dart';
import '../core/auth_storage.dart';
import '../core/agent_debug_log.dart';

class AuthService {
  const AuthService();

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('${ApiConfig.apiBaseUrl}/login');
    late final http.Response response;
    try {
      response = await http.post(
        uri,
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
    } on http.ClientException catch (_) {
      throw Exception(_networkErrorMessage());
    } on SocketException catch (_) {
      throw Exception(_networkErrorMessage());
    }

    await _persistTokenFromResponse(response);
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? nationality,
  }) async {
    final uri = Uri.parse('${ApiConfig.apiBaseUrl}/register');
    late final http.Response response;
    try {
      response = await http.post(
        uri,
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
          'nationality': nationality,
        }),
      );
    } on http.ClientException catch (_) {
      throw Exception(_networkErrorMessage());
    } on SocketException catch (_) {
      throw Exception(_networkErrorMessage());
    }

    await _persistTokenFromResponse(response);
  }

  Future<void> logout() async {
    final token = await AuthStorage.getToken();
    if (token == null || token.isEmpty) {
      await AuthStorage.clearToken();
      return;
    }

    final uri = Uri.parse('${ApiConfig.apiBaseUrl}/logout');
    try {
      await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } finally {
      await AuthStorage.clearToken();
    }
  }

  Future<void> forgotPassword(String email) async {
    final uri = Uri.parse('${ApiConfig.apiBaseUrl}/forgot-password');
    late final http.Response response;
    try {
      response = await http.post(
        uri,
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email}),
      );
    } on http.ClientException catch (_) {
      throw Exception(_networkErrorMessage());
    } on SocketException catch (_) {
      throw Exception(_networkErrorMessage());
    }

    final Map<String, dynamic> data = _decodeJsonObject(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extractErrorMessage(data, response.statusCode));
    }
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String password,
    required String passwordConfirmation,
  }) async {
    final uri = Uri.parse('${ApiConfig.apiBaseUrl}/reset-password');
    late final http.Response response;
    try {
      response = await http.post(
        uri,
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'code': code,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );
    } on http.ClientException catch (_) {
      throw Exception(_networkErrorMessage());
    } on SocketException catch (_) {
      throw Exception(_networkErrorMessage());
    }

    final Map<String, dynamic> data = _decodeJsonObject(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extractErrorMessage(data, response.statusCode));
    }
  }

  Future<void> _persistTokenFromResponse(http.Response response) async {
    final Map<String, dynamic> data = _decodeJsonObject(response.body);

    // #region agent log
    AgentDebugLog.log(
      runId: 'pre-fix',
      hypothesisId: 'J',
      location: 'auth_service.dart:_persistTokenFromResponse',
      message: 'Auth response received',
      data: <String, Object?>{
        'statusCode': response.statusCode,
        'hasAccessToken': data['access_token'] != null && data['access_token'].toString().isNotEmpty,
        'message': data['message']?.toString(),
      },
    );
    // #endregion

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extractErrorMessage(data, response.statusCode));
    }

    final token = data['access_token']?.toString();
    if (token == null || token.isEmpty) {
      throw Exception('Login succeeded but no access token returned.');
    }

    await AuthStorage.saveToken(token);
  }

  Map<String, dynamic> _decodeJsonObject(String source) {
    if (source.trim().isEmpty) {
      return <String, dynamic>{};
    }

    final decoded = jsonDecode(source);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return <String, dynamic>{};
  }

  String _extractErrorMessage(Map<String, dynamic> data, int statusCode) {
    if (data['message'] is String && (data['message'] as String).isNotEmpty) {
      return data['message'] as String;
    }

    final errors = data['errors'];
    if (errors is Map<String, dynamic>) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty) {
          return value.first.toString();
        }
      }
    }

    return 'Request failed (HTTP $statusCode).';
  }

  String _networkErrorMessage() {
    return 'Unable to reach backend API. Check API_BASE_URL, backend server status, and CORS settings.';
  }
}
