import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;

import '../core/api_client.dart';
import '../core/auth_storage.dart';
import '../models/album.dart';
import '../models/chat_message.dart';
import '../models/landmark.dart';
import '../models/user.dart';
import 'api_response.dart';

class ApiService {
  ApiService();

  Dio get _dio => ApiClient.dio;

  // Auth
  Future<ApiResponse<User>> getCurrentUser() async {
    return _safeRequest<User>(
      request: () => _dio.get<dynamic>('/user'),
      parser: (json) => User.fromJson(json),
    );
  }

  Future<ApiResponse<User>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/login',
        data: {
          'email': email,
          'password': password,
        },
      );
      final payload = _asMap(response.data);
      final token = payload['access_token']?.toString();
      if (token != null && token.isNotEmpty) {
        await AuthStorage.saveToken(token);
      }
      return ApiResponse<User>.success(
        data: _parseUserFromAuth(payload),
        statusCode: response.statusCode,
        message: payload['message']?.toString(),
      );
    } on DioException catch (e) {
      return _handleDioError<User>(e);
    } catch (_) {
      return ApiResponse<User>.failure(
        message: 'Unexpected error happened while processing your request.',
      );
    }
  }

  Future<ApiResponse<User>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? nationality,
    String? role,
    String? adminSecret,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
          'nationality': nationality,
          'role': role,
          'admin_secret': adminSecret,
        }..removeWhere((key, value) => value == null),
      );
      final payload = _asMap(response.data);
      final token = payload['access_token']?.toString();
      if (token != null && token.isNotEmpty) {
        await AuthStorage.saveToken(token);
      }
      return ApiResponse<User>.success(
        data: _parseUserFromAuth(payload),
        statusCode: response.statusCode,
        message: payload['message']?.toString(),
      );
    } on DioException catch (e) {
      return _handleDioError<User>(e);
    } catch (_) {
      return ApiResponse<User>.failure(
        message: 'Unexpected error happened while processing your request.',
      );
    }
  }

  Future<ApiResponse<void>> logout() async {
    try {
      final response = await _dio.post<dynamic>('/logout');
      await AuthStorage.clearToken();
      final payload = _asMap(response.data);
      return ApiResponse<void>.success(
        statusCode: response.statusCode,
        message: payload['message']?.toString() ?? 'Logged out successfully.',
      );
    } on DioException catch (e) {
      await AuthStorage.clearToken();
      return _handleDioError<void>(e);
    } catch (_) {
      await AuthStorage.clearToken();
      return ApiResponse<void>.failure(
        message: 'Unexpected error happened during logout.',
      );
    }
  }

  Future<ApiResponse<User>> updateProfile({
    String? name,
    String? nationality,
    String? password,
    String? passwordConfirmation,
    File? avatarFile,
  }) async {
    return _safeRequest<User>(
      request: () async {
        final formData = FormData.fromMap({
          'name': ?name,
          'nationality': ?nationality,
          'password': ?password,
          'password_confirmation': ?passwordConfirmation,
          if (avatarFile != null)
            'avatar': await MultipartFile.fromFile(
              avatarFile.path,
              filename: path.basename(avatarFile.path),
            ),
        });

        return _dio.post<dynamic>('/user/profile', data: formData);
      },
      parser: (json) {
        final userJson = json['user'];
        if (userJson is Map<String, dynamic>) {
          return User.fromJson(userJson);
        }
        return User.fromJson(json);
      },
    );
  }

  // Landmarks
  Future<ApiResponse<List<Landmark>>> getLandmarks() async {
    return _safeRequest<List<Landmark>>(
      request: () => _dio.get<dynamic>('/landmarks'),
      parser: (json) => _parseList(json, Landmark.fromJson),
    );
  }

  Future<ApiResponse<Landmark>> getLandmark(int landmarkId) async {
    return _safeRequest<Landmark>(
      request: () => _dio.get<dynamic>('/landmarks/$landmarkId'),
      parser: (json) => Landmark.fromJson(json),
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> scanLandmark(File imageFile) async {
    return _safeRequest<Map<String, dynamic>>(
      request: () async {
        final formData = FormData.fromMap({
          'image': await MultipartFile.fromFile(
            imageFile.path,
            filename: path.basename(imageFile.path),
          ),
        });
        return _dio.post<dynamic>('/scan', data: formData);
      },
      parser: (json) => json,
    );
  }

  // Translations
  Future<ApiResponse<List<Map<String, dynamic>>>> getTranslations() async {
    return _safeRequest<List<Map<String, dynamic>>>(
      request: () => _dio.get<dynamic>('/translations'),
      parser: (json) => _parseRawMapList(json),
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> createTranslation({
    required File imageFile,
    required String translatedText,
    String? originalText,
    double? confidenceScore,
  }) async {
    return _safeRequest<Map<String, dynamic>>(
      request: () async {
        final formData = FormData.fromMap({
          'translated_text': translatedText,
          if (originalText != null && originalText.trim().isNotEmpty) 'original_text': originalText,
          'confidence_score': ?confidenceScore,
          'image': await MultipartFile.fromFile(
            imageFile.path,
            filename: path.basename(imageFile.path),
          ),
        });
        return _dio.post<dynamic>('/translations', data: formData);
      },
      parser: (json) => json,
    );
  }

  // Chat
  Future<ApiResponse<Map<String, ChatMessage>>> sendMessage(String message) async {
    return _safeRequest<Map<String, ChatMessage>>(
      request: () => _dio.post<dynamic>(
        '/chat',
        data: {'message': message},
      ),
      parser: (json) {
        final userMessageJson = _asMap(json['user_message']);
        final botMessageJson = _asMap(json['bot_message']);
        return {
          'user_message': ChatMessage.fromJson(userMessageJson),
          'bot_message': ChatMessage.fromJson(botMessageJson),
        };
      },
    );
  }

  Future<ApiResponse<List<ChatMessage>>> getChatHistory() async {
    return _safeRequest<List<ChatMessage>>(
      request: () => _dio.get<dynamic>('/chat/history'),
      parser: (json) => _parseList(json, ChatMessage.fromJson),
    );
  }

  // Albums
  Future<ApiResponse<List<Album>>> getAlbums() async {
    return _safeRequest<List<Album>>(
      request: () => _dio.get<dynamic>('/albums'),
      parser: (json) => _parseList(json, Album.fromJson),
    );
  }

  Future<ApiResponse<Album>> createAlbum({
    required String title,
    String? description,
  }) async {
    return _safeRequest<Album>(
      request: () => _dio.post<dynamic>(
        '/albums',
        data: {
          'title': title,
          'description': description,
        }..removeWhere((key, value) => value == null),
      ),
      parser: (json) => Album.fromJson(json),
    );
  }

  Future<ApiResponse<Album>> getAlbum(int albumId) async {
    return _safeRequest<Album>(
      request: () => _dio.get<dynamic>('/albums/$albumId'),
      parser: (json) => Album.fromJson(json),
    );
  }

  // Favorites
  Future<ApiResponse<List<Landmark>>> getFavorites() async {
    return _safeRequest<List<Landmark>>(
      request: () => _dio.get<dynamic>('/favorites'),
      parser: (json) => _parseList(json, Landmark.fromJson),
    );
  }

  Future<ApiResponse<void>> addFavorite(int landmarkId) async {
    return _safeRequest<void>(
      request: () => _dio.post<dynamic>(
        '/favorites',
        data: {'landmark_id': landmarkId},
      ),
      parser: (_) {},
    );
  }

  Future<ApiResponse<void>> removeFavorite(int landmarkId) async {
    return _safeRequest<void>(
      request: () => _dio.delete<dynamic>('/favorites/$landmarkId'),
      parser: (_) {},
    );
  }

  Future<ApiResponse<T>> _safeRequest<T>({
    required Future<Response<dynamic>> Function() request,
    required T Function(Map<String, dynamic> json) parser,
  }) async {
    try {
      final response = await request();
      final payload = _asMap(response.data);
      return ApiResponse<T>.success(
        data: parser(payload),
        statusCode: response.statusCode,
        message: payload['message']?.toString(),
      );
    } on DioException catch (e) {
      return _handleDioError<T>(e);
    } catch (_) {
      return ApiResponse<T>.failure(
        message: 'Unexpected error happened while processing your request.',
      );
    }
  }

  ApiResponse<T> _handleDioError<T>(DioException exception) {
    final statusCode = exception.response?.statusCode;
    final payload = _asMap(exception.response?.data);
    return ApiResponse<T>.failure(
      statusCode: statusCode,
      message: _extractMessage(payload, statusCode),
      errors: _extractValidationErrors(payload),
    );
  }

  String _extractMessage(Map<String, dynamic> payload, int? statusCode) {
    final message = payload['message']?.toString();
    if (message != null && message.isNotEmpty) {
      return message;
    }
    return statusCode != null ? 'Request failed (HTTP $statusCode).' : 'Request failed.';
  }

  Map<String, List<String>>? _extractValidationErrors(Map<String, dynamic> payload) {
    final errors = payload['errors'];
    if (errors is! Map<String, dynamic>) {
      return null;
    }

    final parsed = <String, List<String>>{};
    for (final entry in errors.entries) {
      final value = entry.value;
      if (value is List) {
        parsed[entry.key] = value.map((item) => item.toString()).toList();
      } else if (value != null) {
        parsed[entry.key] = [value.toString()];
      }
    }

    return parsed.isEmpty ? null : parsed;
  }

  User _parseUserFromAuth(Map<String, dynamic> payload) {
    final userJson = payload['user'];
    if (userJson is Map<String, dynamic>) {
      return User.fromJson(userJson);
    }
    return User.fromJson(payload);
  }

  List<T> _parseList<T>(
    Map<String, dynamic> payload,
    T Function(Map<String, dynamic>) parser,
  ) {
    final rawList = _extractListPayload(payload);
    if (rawList is! List) {
      return <T>[];
    }
    return rawList
        .whereType<Map<String, dynamic>>()
        .map(parser)
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _parseRawMapList(Map<String, dynamic> payload) {
    final rawList = _extractListPayload(payload);
    if (rawList is! List) {
      return <Map<String, dynamic>>[];
    }
    return rawList.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  List<dynamic>? _extractListPayload(Map<String, dynamic> payload) {
    if (payload['data'] is List) {
      return payload['data'] as List<dynamic>;
    }
    if (payload['items'] is List) {
      return payload['items'] as List<dynamic>;
    }
    if (payload.length == 1) {
      final value = payload.values.first;
      if (value is List) {
        return value;
      }
    }
    return null;
  }

  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is List) {
      return <String, dynamic>{'data': raw};
    }
    return <String, dynamic>{};
  }
}
