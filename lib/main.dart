import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/app_colors.dart';
import 'core/app_localizations.dart';
import 'core/session_navigation.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/home/favorites.dart'; // ✅ مهم
import 'core/theme_provider.dart'; // Import ThemeProvider from the separate file
import 'core/language_provider.dart';
import 'screens/home/gallery_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await loadFavorites(); //  تحميل الفافوريت
  await GalleryStore.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

/// Holds light and dark [ThemeData] for the app, enforcing theme-based UI.
class AppThemes {
  static ThemeData light = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      surface: const Color(0xFFF5F6FA),
    ),
    scaffoldBackgroundColor: const Color(0xFFF5F6FA),
    cardColor: const Color(0xFFF7F7FA),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF5F6FA),
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Color(0xFF141518),
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
      iconTheme: IconThemeData(color: Color(0xFF141518)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(AppColors.primary),
        foregroundColor: WidgetStatePropertyAll(Colors.white),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.transparent,
      hintStyle: const TextStyle(
        color: Color(0xFFB0B3B8),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFDBDBE4), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1),
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF141518), fontFamilyFallback: ['Arial', 'sans-serif']),
      bodyMedium: TextStyle(color: Color(0xFF39394D), fontFamilyFallback: ['Arial', 'sans-serif']),
      bodySmall: TextStyle(color: Color(0xFF717187), fontFamilyFallback: ['Arial', 'sans-serif']),
      titleLarge: TextStyle(color: Color(0xFF141518), fontWeight: FontWeight.bold, fontFamilyFallback: ['Arial', 'sans-serif']),
    ),
    iconTheme: const IconThemeData(
      color: Color(0xFF141518),
    ),
    dividerColor: Color(0xFFE0E0E3),
  );

  static ThemeData dark = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.primary,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF181A20),
    cardColor: const Color(0xFF23262F),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF181A20),
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(AppColors.primary),
        foregroundColor: WidgetStatePropertyAll(Colors.white),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF23262F),
      hintStyle: const TextStyle(
        color: Color(0xFFB0B3B8),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF353941), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1),
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white, fontFamilyFallback: ['Arial', 'sans-serif']),
      bodyMedium: TextStyle(color: Color(0xFFDBDBE4), fontFamilyFallback: ['Arial', 'sans-serif']),
      bodySmall: TextStyle(color: Color(0xFFB0B3B8), fontFamilyFallback: ['Arial', 'sans-serif']),
      titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamilyFallback: ['Arial', 'sans-serif']),
    ),
    iconTheme: const IconThemeData(
      color: Colors.white,
    ),
    dividerColor: Color(0xFF353941),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LanguageProvider>(
      builder: (context, themeProvider, languageProvider, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          navigatorKey: SessionNavigation.navigatorKey,
          theme: AppThemes.light,
          darkTheme: AppThemes.dark,
          themeMode: themeProvider.themeMode,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'), // English
            Locale('ar'), // Arabic
          ],
          locale: languageProvider.selectedLocale,
          home: const SplashScreen(),
        );
      },
    );
  }
}
