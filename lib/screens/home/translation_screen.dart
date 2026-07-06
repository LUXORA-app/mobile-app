import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/language_provider.dart';
import '../../services/ml_api_service.dart';
import '../../services/api_service.dart';
import '../../widgets/app_background.dart';
import 'gallery_store.dart';

class TranslationScreen extends StatefulWidget {
  final File imageFile;

  /// Pass [savedTranslation] when opening from Gallery (already translated).
  final String? savedTranslation;
  final String? galleryEntryId;
  final String? initialLanguage;
  
  const TranslationScreen({
    super.key,
    required this.imageFile,
    this.savedTranslation,
    this.galleryEntryId,
    this.initialLanguage,
  });

  @override
  State<TranslationScreen> createState() => _TranslationScreenState();
}

class _TranslationScreenState extends State<TranslationScreen> {
  // ── State ────────────────────────────────────────────────────
  late String _selectedLanguage;
  String? _lastSyncedProviderLanguage;
  String? _translation;
  bool _isLoading = false;
  String? _error;
  bool _isSaved = false;
  bool _isSaving = false;

  final List<String> _languages = [
    'English',
    'Arabic',
    
  ];

  
  // ── Lifecycle ────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    if (widget.initialLanguage != null) {
      _selectedLanguage = widget.initialLanguage!;
    } else {
      _selectedLanguage = Provider.of<LanguageProvider>(context, listen: false).selectedLanguage;
    }
    // Keep last seen provider language so we can react to future changes.
    _lastSyncedProviderLanguage = Provider.of<LanguageProvider>(context, listen: false).selectedLanguage;
    if (widget.savedTranslation != null) {
      _translation = widget.savedTranslation;
      _isSaved = true;
    } else {
      _translate();
      _isSaved = false;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final providerLanguage = Provider.of<LanguageProvider>(context).selectedLanguage;
    if (_lastSyncedProviderLanguage == providerLanguage) return;

    _lastSyncedProviderLanguage = providerLanguage;

    // Only auto-sync when the user is currently on English/Arabic.
    // (If they picked French/Spanish/etc manually, we don't override it.)
    final isCurrentlyAppLanguageChoice =
        _selectedLanguage == 'English' || _selectedLanguage == 'Arabic';
    if (!isCurrentlyAppLanguageChoice) return;

    if (_selectedLanguage != providerLanguage) {
      _selectedLanguage = providerLanguage;
      _translate();
    }
  }

  // ── Translation using ML API from app.py ──
  Future<void> _translate() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _translation = null;
    });

    try {
      // API may return `translation` as a nested object (new shape) or plain string (legacy).
      final result = await MlApiService.translateHieroglyphics(
        widget.imageFile,
        language: _selectedLanguage,
      );
      final translationPayload = result['translation'];
      final translatedText = switch (translationPayload) {
        Map<String, dynamic> map => map['translated_text']?.toString() ?? '',
        _ => translationPayload?.toString() ?? '',
      };
      if (translatedText.trim().isEmpty) {
        throw Exception('Translation text is missing in API response.');
      }
      setState(() => _translation = translatedText);
    } catch (e) {
      setState(() => _error = 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  
  bool get _openedFromGallery => widget.galleryEntryId != null;

  Future<void> _saveToGallery() async {
    if (_translation == null || _translation!.trim().isEmpty || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      // First check if already saved locally
      final existingLocal = GalleryStore.findByImagePath(widget.imageFile.path);
      if (existingLocal != null) {
        setState(() {
          _isSaved = true;
          _isSaving = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Already saved!')),
          );
        }
        return;
      }

      // Save to local gallery (so it shows up in app's gallery)
      await GalleryStore.save(
        imagePath: widget.imageFile.path,
        translation: _translation!,
        language: _selectedLanguage,
      );

      // Save to backend (so user can access from web)
      final apiService = ApiService();
      await apiService.createTranslation(
        imageFile: widget.imageFile,
        translatedText: _translation!,
        originalText: 'Scan in $_selectedLanguage',
        confidenceScore: 0.0,
      );

      setState(() {
        _isSaved = true;
        _isSaving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved to Gallery!')),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    }
  }

  // ── Language dropdown handler ────────────────────────────────
  void _onLanguageChanged(String? lang) {
    if (lang == null || lang == _selectedLanguage) return;
    
    // If opened from gallery, allow translation even with saved translation
    setState(() => _selectedLanguage = lang);
    
    // Always translate when language changes, even if we have a saved translation
    _translate();
  }

  // ── Delete confirmation ──────────────────────────────────────
  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete scan?'),
        content: const Text(
          'This will remove the image and its translation from your gallery.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // close dialog
              if (widget.galleryEntryId != null) {
                await GalleryStore.removeById(widget.galleryEntryId!);
              }
              if (mounted) {
                Navigator.pop(context); // go back to previous screen
              }
            },
            child: Text('Delete', style: TextStyle(color: Colors.red.shade600)),
          ),
        ],
      ),
    );
  }

  // ── UI ───────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 12, 10),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.primary,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    _openedFromGallery ? 'Gallery' : 'Scan',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      widget.imageFile,
                      width: double.infinity,
                      height: 260,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Language',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      //color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      //color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedLanguage,
                        isExpanded: true,
                        icon: const Icon(
                          Icons.keyboard_arrow_up_rounded,
                          color: AppColors.primary,
                        ),
                        items: _languages
                            .map(
                              (lang) => DropdownMenuItem(
                                value: lang,
                                child: Text(
                                  lang,
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: _onLanguageChanged,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Translation',
                    style: TextStyle(
                      fontSize: 52,
                      height: 0.9,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            CircularProgressIndicator(color: AppColors.primary),
                            SizedBox(height: 16),
                            Text(
                              'Translating…',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (_error != null)
                    _ErrorCard(message: _error!, onRetry: _translate)
                  else if (_translation != null)
                    Text(
                      _translation!,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.45,
                        //colorColor.fromARGB(221, 3, 1, 1)87,
                      ),
                    )
                  else
                    const Text(
                      'No translation available.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _openedFromGallery
                      ? _confirmDelete
                      : (_isSaving || _isSaved ? null : () async {
                          await _saveToGallery();
                        }),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _openedFromGallery
                        ? Colors.red.shade50
                        : AppColors.primary.withValues(alpha: 0.12),
                    foregroundColor: _openedFromGallery
                        ? Colors.red
                        : AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 2,
                        )
                      : Icon(
                          _openedFromGallery
                              ? Icons.delete_outline_rounded
                              : (_isSaved
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded),
                          size: 26,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error card helper ────────────────────────────────────────────
class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: TextStyle(color: Colors.red.shade700, fontSize: 14),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
