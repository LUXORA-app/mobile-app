import 'package:flutter/material.dart';
import '../../core/app_localizations.dart';
import '../../core/auth_storage.dart';
import '../../core/api_media_url.dart';
import '../../models/landmark.dart';
import '../../services/api_service.dart';
import '../../widgets/app_background.dart';
import 'details_screen.dart';

class ExploreScreen extends StatefulWidget {
  final bool showBackButton;

  const ExploreScreen({super.key, this.showBackButton = false});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final ApiService _apiService = ApiService();
  Future<List<Place>>? _placesFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_placesFuture == null) {
      _placesFuture = _fetchLandmarks(AppLocalizations.of(context));
    }
  }

  /// GET /api/landmarks — matches [routes/api.php] + Node `api.get('/landmarks')`.
  Future<List<Place>> _fetchLandmarks(AppLocalizations loc) async {
    final token = await AuthStorage.getToken();
    if (token == null || token.isEmpty) {
      throw Exception(loc.translate('pleaseLoginFirst'));
    }
    final response = await _apiService.getLandmarks();
    if (!response.isSuccess) {
      throw Exception(
        response.message ?? 'Failed to load landmarks (HTTP ${response.statusCode}).',
      );
    }
    final list = response.data ?? [];
    return list.map((item) => _mapLandmarkToPlace(item, loc)).toList(growable: false);
  }

  Place _mapLandmarkToPlace(Landmark item, AppLocalizations loc) {
    final resolved = ApiMediaUrl.resolve(item.imageUrl);
    final hasRemote = resolved != null && resolved.isNotEmpty;
    return Place(
      id: item.id,
      title: item.name,
      subtitle: item.location ?? loc.translate('unknownLocation'),
      image: hasRemote ? resolved : 'assets/images/logo_trans.png',
      lat: item.latitude ?? 24.0889,
      lng: item.longitude ?? 32.8998,
      about: item.description ?? loc.translate('noDescriptionAvailable'),
      isAssetImage: !hasRemote,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final loc = AppLocalizations.of(context);

    return AppBackground(
      child: SafeArea(
        child: Column(
          children: [
            if (widget.showBackButton)
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            Expanded(
              child: FutureBuilder<List<Place>>(
                future: _placesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          snapshot.error.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    );
                  }
                  final places = snapshot.data ?? [];
                  if (places.isEmpty) {
                    return Center(child: Text(loc.translate('noLandmarksYet')));
                  }
                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Image.asset(
                              'assets/images/logo_trans.png',
                              height: screenHeight * 0.14,
                            ),
                          ),
                          const SizedBox(height: 20),
                          sectionHeader(context, loc.translate('landmarks'), loc),
                          const SizedBox(height: 14),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: places.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: 0.78,
                            ),
                            itemBuilder: (context, index) {
                              return placeCard(places[index], screenHeight);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget placeCard(Place place, double screenHeight) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailsPage(place: place),
          ),
        ).then((_) {
          setState(() {});
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: place.isAssetImage
                  ? Image.asset(
                      place.image,
                      height: screenHeight * 0.17,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Image.network(
                      place.image,
                      height: screenHeight * 0.17,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: screenHeight * 0.17,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.broken_image),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    place.subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

Widget sectionHeader(BuildContext context, String title, AppLocalizations loc) {
  final theme = Theme.of(context);
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      Text(
        loc.translate('seeMore'),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}

class Place {
  final int id;
  final String title;
  final String subtitle;
  final String image;
  final double lat;
  final double lng;
  final String about;
  final bool isAssetImage;

  Place({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.image,
    required this.lat,
    required this.lng,
    required this.about,
    this.isAssetImage = true,
  });

  @override
  bool operator ==(Object other) {
    return other is Place &&
        other.id == id &&
        other.title == title &&
        other.lat == lat &&
        other.lng == lng;
  }

  @override
  int get hashCode =>
      id.hashCode ^ title.hashCode ^ lat.hashCode ^ lng.hashCode;
}
