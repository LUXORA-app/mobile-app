import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class MlApiService {
  // Use 10.0.2.2 for Android emulator to access host machine's localhost
  // Use actual IP for physical device on same network
  static const String mlBaseUrl = 'http://10.0.2.2:5000/api'; // ML service

  // =========================
  // Translation
  // =========================
  static Future<Map<String, dynamic>> translateHieroglyphics(File imageFile, {String language = 'English'}) async {
    try {
      debugPrint('🔄 Starting translation to $language...');
      
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$mlBaseUrl/translate'),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
        ),
      );
      request.fields['language'] = language;

      final response = await request.send();

      debugPrint('📡 Translation Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final result = json.decode(responseBody);
        debugPrint('✅ Translation Result: $result');
        return result;
      } else {
        debugPrint('❌ Translation Failed: ${response.statusCode}');
        throw Exception('Translation failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Translation Error: $e');
      throw Exception('Translation error: $e');
    }
  }

  // =========================
  // Object Detection (YOLO)
  // =========================
  static Future<Map<String, dynamic>> detectObjects(File imageFile) async {
    try {
      debugPrint('🔄 Starting object detection...');
      
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$mlBaseUrl/predict-yolo'),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
        ),
      );

      final response = await request.send();

      debugPrint('📡 Object Detection Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final result = json.decode(responseBody);
        debugPrint('✅ Object Detection Result: $result');
        return result;
      } else {
        debugPrint('❌ Object Detection Failed: ${response.statusCode}');
        throw Exception('Object detection failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Object Detection Error: $e');
      throw Exception('Object detection error: $e');
    }
  }

  // =========================
  // Health Check
  // =========================
  static Future<Map<String, dynamic>> checkHealth() async {
    try {
      debugPrint('🔄 Checking ML service health...');
      
      final response = await http.get(
        Uri.parse('$mlBaseUrl/health'),
      );

      debugPrint('📡 Health Check Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        debugPrint('✅ ML Service Healthy: $result');
        return result;
      } else {
        debugPrint('❌ Health Check Failed: ${response.statusCode}');
        throw Exception('Health check failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Health Check Error: $e');
      throw Exception('Health check error: $e');
    }
  }

  // =========================
  // Test Connection
  // =========================
  static Future<bool> testConnection() async {
    try {
      debugPrint('🔄 Testing ML service connection...');
      
      final health = await checkHealth();
      final isHealthy = health['status'] == 'healthy';
      
      debugPrint('📊 ML Service Status: ${isHealthy ? "CONNECTED" : "DISCONNECTED"}');
      
      return isHealthy;
    } catch (e) {
      debugPrint('❌ Connection Test Error: $e');
      return false;
    }
  }
}
