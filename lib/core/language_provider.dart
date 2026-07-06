import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _key = 'selected_locale';
  Locale _selectedLocale = const Locale('en');

  Locale get selectedLocale => _selectedLocale;
  String get selectedLanguage => _selectedLocale.languageCode == 'en' ? 'English' : 'Arabic';

  LanguageProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_key) ?? 'en';
    _selectedLocale = Locale(languageCode);
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    _selectedLocale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.languageCode);
  }

  Future<void> setLanguage(String language) async {
    final locale = language == 'English' ? const Locale('en') : const Locale('ar');
    await setLocale(locale);
  }
}
