import 'package:flutter/material.dart';
import '../../core/app_localizations.dart';
import 'chat_screen.dart';
import 'explore_screen.dart';
import 'scan_screen.dart';
import 'gallery_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  /// Default tab: Explore (Chat is not a route — back button there used to pop nothing).
  int currentIndex = 0;

  final List<Widget> screens = const [
    ExploreScreen(),
    ChatScreen(),
    ScanScreen(),
    GalleryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    return Scaffold(
      body: screens[currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },

        type: BottomNavigationBarType.fixed,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: theme.colorScheme.onSurfaceVariant,

        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            label: loc.translate('explore'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: loc.translate('chatBot'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt_outlined),
            label: loc.translate('scan'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.image_outlined),
            label: loc.translate('gallery'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: loc.translate('settings'),
          ),
        ],
      ),
    );
  }
}