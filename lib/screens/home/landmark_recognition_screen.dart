import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../services/api_service.dart';
import '../../widgets/app_background.dart';

class LandmarkRecognitionScreen extends StatefulWidget {
  final File imageFile;

  const LandmarkRecognitionScreen({super.key, required this.imageFile});

  @override
  State<LandmarkRecognitionScreen> createState() =>
      _LandmarkRecognitionScreenState();
}

class _LandmarkRecognitionScreenState extends State<LandmarkRecognitionScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _error;
  String? _topLandmark;
  List<_LandmarkScore> _predictions = const [];

  @override
  void initState() {
    super.initState();
    _recognizeLandmark();
  }

  Future<void> _recognizeLandmark() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.scanLandmark(widget.imageFile);
      if (!mounted) {
        return;
      }

      if (!response.isSuccess || response.data == null) {
        setState(() {
          _error = response.message ?? 'Failed to analyze this image. Please try again.';
        });
        return;
      }

      final data = response.data!;
      final landmarkName = data['landmark_name']?.toString() ?? 'Unknown Landmark';
      final confidenceRaw = data['confidence'];
      final confidence = confidenceRaw is num
          ? confidenceRaw.toDouble()
          : double.tryParse(confidenceRaw?.toString() ?? '') ?? 0.0;

      final candidates = <_LandmarkScore>[
        _LandmarkScore(name: landmarkName, confidence: confidence.clamp(0.0, 1.0)),
      ];

      setState(() {
        _predictions = candidates;
        _topLandmark = landmarkName;
      });
    } catch (_) {
      setState(
        () => _error = 'Failed to analyze this image. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

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
                const Expanded(
                  child: Text(
                    'Landmark Recognition',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 22,
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
                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 42),
                        child: Column(
                          children: [
                            CircularProgressIndicator(color: AppColors.primary),
                            SizedBox(height: 14),
                            Text(
                              'Recognizing landmark...',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (_error != null)
                    _ErrorCard(message: _error!, onRetry: _recognizeLandmark)
                  else
                    _ResultsCard(
                      topLandmark: _topLandmark ?? 'Unknown',
                      predictions: _predictions,
                    ),
                  
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultsCard extends StatelessWidget {
  final String topLandmark;
  final List<_LandmarkScore> predictions;

  const _ResultsCard({required this.topLandmark, required this.predictions});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Result',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            topLandmark,
            style: const TextStyle(
              fontSize: 28,
              height: 1.05,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 18),
          ...predictions.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ScoreRow(item: item),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final _LandmarkScore item;

  const _ScoreRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final percent = (item.confidence * 100).round();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            Text(
              '$percent%',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: item.confidence,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _LandmarkScore {
  final String name;
  final double confidence;

  const _LandmarkScore({required this.name, required this.confidence});
}

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
          const SizedBox(height: 10),
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
