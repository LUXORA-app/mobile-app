import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'favorites.dart';
import '../../core/agent_debug_log.dart';

class DetailsPage extends StatefulWidget {
  final dynamic place;

  const DetailsPage({super.key, required this.place});

  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  @override
  void initState() {
    super.initState();

    // #region agent log
    AgentDebugLog.log(
      runId: 'pre-fix',
      hypothesisId: 'C',
      location: 'details_screen.dart:initState',
      message: 'DetailsPage initState',
      data: <String, Object?>{
        'lat': (widget.place as dynamic).lat,
        'lng': (widget.place as dynamic).lng,
      },
    );
    // #endregion

    _probeOsmTile();
  }

  Future<void> _probeOsmTile() async {
    try {
      final uri = Uri.parse('https://tile.openstreetmap.org/0/0/0.png');
      final res = await http.get(uri).timeout(const Duration(seconds: 5));
      // #region agent log
      AgentDebugLog.log(
        runId: 'pre-fix',
        hypothesisId: 'C',
        location: 'details_screen.dart:_probeOsmTile:result',
        message: 'OSM tile probe completed',
        data: <String, Object?>{'statusCode': res.statusCode},
      );
      // #endregion
    } catch (e) {
      // #region agent log
      AgentDebugLog.log(
        runId: 'pre-fix',
        hypothesisId: 'C',
        location: 'details_screen.dart:_probeOsmTile:error',
        message: 'OSM tile probe failed',
        data: <String, Object?>{'error': e.toString()},
      );
      // #endregion
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final LatLng location = LatLng(widget.place.lat, widget.place.lng);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        iconTheme: theme.iconTheme,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.place.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.place.subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          /// 🗺️ Map
          SizedBox(
            height: 180,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: location,
                initialZoom: 14,
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  // 🔥 FIXED: Added userAgentPackageName to follow OSM policy
                  userAgentPackageName: 'com.yourdomain.luxora', 
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: location,
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.location_on,
                        color: theme.colorScheme.error,
                        size: 35,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          /// Content
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// 🖼 Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: widget.place.isAssetImage
                        ? Image.asset(
                            widget.place.image,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Image.network(
                            widget.place.image,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 180,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image_outlined),
                            ),
                          ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    widget.place.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    widget.place.subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    "ABOUT",
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurfaceVariant,
                      letterSpacing: 1,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    widget.place.about,
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
                  ),

                  const Spacer(),

                  /// ❤️ Favorite Button
                  Center(
                    child: GestureDetector(
                      onTap: () async {
                        setState(() {
                          if (favoritePlaces.contains(widget.place)) {
                            favoritePlaces.remove(widget.place);
                          } else {
                            favoritePlaces.add(widget.place);
                          }
                        });

                        await saveFavorites();
                      },
                      child: Container(
                        width: 160,
                        height: 50,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          favoritePlaces.contains(widget.place)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: favoritePlaces.contains(widget.place)
                              ? theme.colorScheme.error
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
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