import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/agent_debug_log.dart';

class GalleryEntry {
  final String id;
  final String imagePath;
  final String title;
  final String translation;
  final String language;
  final DateTime createdAt;

  const GalleryEntry({
    required this.id,
    required this.imagePath,
    required this.title,
    required this.translation,
    required this.language,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imagePath': imagePath,
      'title': title,
      'translation': translation,
      'language': language,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory GalleryEntry.fromJson(Map<String, dynamic> json) {
    final createdRaw = json['createdAt'];
    final createdMs = createdRaw is int ? createdRaw : int.tryParse('$createdRaw');
    return GalleryEntry(
      id: json['id']?.toString() ?? '',
      imagePath: json['imagePath']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      translation: json['translation']?.toString() ?? '',
      language: json['language']?.toString() ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdMs ?? 0),
    );
  }
}

class GalleryStore {
  GalleryStore._();

  static final ValueNotifier<List<GalleryEntry>> entries =
      ValueNotifier<List<GalleryEntry>>([]);

  static const String _prefsKey = 'gallery_entries_v1';

  static Future<Directory> _getGalleryDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final galleryDir = Directory('${appDocDir.path}/gallery');
    if (!await galleryDir.exists()) {
      await galleryDir.create(recursive: true);
    }
    return galleryDir;
  }

  static Future<String> _copyImageToGallery(String sourceImagePath, String id) async {
    final galleryDir = await _getGalleryDirectory();
    final fileExtension = path.extension(sourceImagePath);
    final newFileName = '$id$fileExtension';
    final newFilePath = path.join(galleryDir.path, newFileName);

    final sourceFile = File(sourceImagePath);
    await sourceFile.copy(newFilePath);
    return newFilePath;
  }

  static Future<void> _deleteImageFile(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting image file: $e');
    }
  }

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_prefsKey) ?? const <String>[];
      final loaded = <GalleryEntry>[];
      
      for (final item in raw) {
        try {
          final decoded = jsonDecode(item) as Map<String, dynamic>;
          loaded.add(GalleryEntry.fromJson(decoded));
        } catch (e) {
          debugPrint('Failed to decode gallery entry: $e');
          continue;
        }
      }
      
      entries.value = loaded;

      AgentDebugLog.log(
        runId: 'fix',
        hypothesisId: 'E',
        location: 'gallery_store.dart:init',
        message: 'GalleryStore init loaded',
        data: <String, Object?>{'loadedCount': loaded.length},
      );
    } catch (e) {
      debugPrint('GalleryStore init failed: $e');
      AgentDebugLog.log(
        runId: 'fix',
        hypothesisId: 'E',
        location: 'gallery_store.dart:init:error',
        message: 'GalleryStore init failed',
        data: <String, Object?>{'error': e.toString()},
      );
      entries.value = [];
    }
  }

  static GalleryEntry? findByImagePath(String imagePath) {
    for (final entry in entries.value) {
      if (entry.imagePath == imagePath) return entry;
    }
    return null;
  }

  static bool isSaved(String imagePath) => findByImagePath(imagePath) != null;

  static Future<GalleryEntry> save({
    required String imagePath,
    required String translation,
    required String language,
  }) async {
    final existing = findByImagePath(imagePath);
    if (existing != null) return existing;

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final nextIndex = entries.value.length + 1;
    final permanentImagePath = await _copyImageToGallery(imagePath, id);
    
    final entry = GalleryEntry(
      id: id,
      imagePath: permanentImagePath,
      title: 'Mural $nextIndex',
      translation: translation,
      language: language,
      createdAt: DateTime.now(),
    );

    entries.value = [entry, ...entries.value];
    await _persist();
    
    AgentDebugLog.log(
      runId: 'fix',
      hypothesisId: 'E',
      location: 'gallery_store.dart:save',
      message: 'GalleryStore saved entry',
      data: <String, Object?>{'count': entries.value.length},
    );
    
    return entry;
  }

  static Future<void> removeById(String id) async {
    final entryToRemove = entries.value.firstWhere((entry) => entry.id == id);
    await _deleteImageFile(entryToRemove.imagePath);
    
    entries.value = entries.value.where((entry) => entry.id != id).toList();
    await _persist();
    
    AgentDebugLog.log(
      runId: 'fix',
      hypothesisId: 'E',
      location: 'gallery_store.dart:removeById',
      message: 'GalleryStore removed entry',
      data: <String, Object?>{'count': entries.value.length},
    );
  }

  static Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = entries.value
          .map((e) => jsonEncode(e.toJson()))
          .toList(growable: false);
      await prefs.setStringList(_prefsKey, list);
      debugPrint('GalleryStore persisted ${list.length} entries');
    } catch (e) {
      debugPrint('GalleryStore persist failed: $e');
      rethrow;
    }
  }
}
