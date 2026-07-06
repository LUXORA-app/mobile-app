import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_localizations.dart';
import '../../widgets/app_background.dart';
import '../../core/agent_debug_log.dart';
import 'gallery_store.dart';
import 'translation_screen.dart';
import 'dart:io';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  @override
  void initState() {
    super.initState();
    // #region agent log
    AgentDebugLog.log(
      runId: 'pre-fix',
      hypothesisId: 'B',
      location: 'gallery_screen.dart:initState',
      message: 'GalleryScreen initState (local store mode)',
      data: const <String, Object?>{},
    );
    // #endregion
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return AppBackground(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Text(
              loc.translate('gallery'),
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ValueListenableBuilder<List<GalleryEntry>>(
                valueListenable: GalleryStore.entries,
                builder: (context, entries, _) {
                  // #region agent log
                  AgentDebugLog.log(
                    runId: 'pre-fix',
                    hypothesisId: 'B',
                    location: 'gallery_screen.dart:build',
                    message: 'Gallery build (local entries)',
                    data: <String, Object?>{'entriesCount': entries.length},
                  );
                  // #endregion

                  if (entries.isEmpty) {
                    return Center(
                      child: Text(
                        loc.translate('noScansYet'),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      final file = File(entry.imagePath);
                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          // #region agent log
                          AgentDebugLog.log(
                            runId: 'pre-fix',
                            hypothesisId: 'B',
                            location: 'gallery_screen.dart:onTapEntry',
                            message: 'Gallery entry tapped',
                            data: <String, Object?>{'id': entry.id, 'language': entry.language},
                          );
                          // #endregion

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TranslationScreen(
                                imageFile: file,
                                savedTranslation: entry.translation,
                                galleryEntryId: entry.id,
                                initialLanguage: entry.language,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: const Color(0x66DDE2FF),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: file.existsSync()
                                    ? Image.file(
                                        file,
                                        width: 72,
                                        height: 72,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        width: 72,
                                        height: 72,
                                        color: Colors.white.withOpacity(0.7),
                                        child: const Icon(Icons.broken_image_outlined),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      entry.language,
                                      style: const TextStyle(color: Colors.black54),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      entry.translation,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.black87),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
