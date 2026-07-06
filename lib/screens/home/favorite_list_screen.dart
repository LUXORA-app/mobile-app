import 'package:flutter/material.dart';
import '../../widgets/app_background.dart';
import '../../core/app_colors.dart'; // 👈 مهم
import '../home/explore_screen.dart';
import '../home/details_screen.dart';
import 'favorites.dart';
import '../../core/agent_debug_log.dart';

class FavoriteListScreen extends StatefulWidget {
  const FavoriteListScreen({super.key});

  @override
  State<FavoriteListScreen> createState() => _FavoriteListScreenState();
}

class _FavoriteListScreenState extends State<FavoriteListScreen> {
  @override
  void initState() {
    super.initState();
    // #region agent log
    AgentDebugLog.log(
      runId: 'pre-fix',
      hypothesisId: 'F',
      location: 'favorite_list_screen.dart:initState',
      message: 'FavoriteListScreen initState',
      data: <String, Object?>{'count': favoritePlaces.length},
    );
    // #endregion
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBackground(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              /// 🔙 Back
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

              const SizedBox(height: 10),

              /// ✅ العنوان زي Settings 100%
              const Center(
                child: Text(
                  "Favourite List",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary, // 👈 نفس اللون بالظبط
                  ),
                ),
              ),

              const SizedBox(height: 10),

              /// 🔷 Logo
              Image.asset(
                'assets/images/logo_trans.png',
                height: 90,
              ),

              const SizedBox(height: 20),

              /// ❤️ Content
              Expanded(
                child: favoritePlaces.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "No favorites yet 😢",
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ExploreScreen(showBackButton: true),
                                  ),
                                );
                              },
                              child: Text(
                                "Go to Explore",
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: theme.colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: favoritePlaces.length,
                        itemBuilder: (context, index) {
                          final place = favoritePlaces[index];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: theme.brightness == Brightness.light
                                  ? const Color(0xFFEDEFF5)
                                  : theme.cardColor,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.shadowColor.withOpacity(0.1),
                                  blurRadius: 8,
                                ),
                              ],
                              border: Border.all(
                                color: theme.colorScheme.outline.withOpacity(0.3),
                                width: 0.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                /// Image
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(18),
                                  ),
                                  child: place.isAssetImage
                                      ? Image.asset(
                                          place.image,
                                          height: 160,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.network(
                                          place.image,
                                          height: 160,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            height: 160,
                                            color: Colors.grey.shade300,
                                            child: const Icon(Icons.broken_image_outlined),
                                          ),
                                        ),
                                ),

                                /// Text
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        place.title,
                                        style: theme.textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        place.subtitle,
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),

                                /// Buttons
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Row(
                                    children: [
                                      /// Delete
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () async {
                                            setState(() {
                                              favoritePlaces.removeAt(index);
                                            });
                                            await saveFavorites();
                                          },
                                          child: Container(
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.surfaceContainerHighest,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Center(
                                              child: Text(
                                                "Delete",
                                                style: theme.textTheme.bodyLarge,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(width: 10),

                                      /// About
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    DetailsPage(place: place),
                                              ),
                                            ).then((_) {
                                              setState(() {});
                                            });
                                          },
                                          child: Container(
                                            height: 40,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  theme.colorScheme.primary,
                                                  theme.colorScheme.primary.withOpacity(0.8),
                                                ],
                                              ),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Center(
                                              child: Text(
                                                "About",
                                                style: theme.textTheme.bodyLarge?.copyWith(
                                                  color: theme.colorScheme.onPrimary,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}