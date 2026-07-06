import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../home/explore_screen.dart';

List<Place> favoritePlaces = [];

/// 💾 حفظ البيانات
Future<void> saveFavorites() async {
  final prefs = await SharedPreferences.getInstance();

  List<String> data = favoritePlaces.map((place) {
    return jsonEncode({
      "id": place.id,
      "title": place.title,
      "subtitle": place.subtitle,
      "image": place.image,
      "lat": place.lat,
      "lng": place.lng,
      "about": place.about,
      "isAssetImage": place.isAssetImage,
    });
  }).toList();

  await prefs.setStringList("favorites", data);
}

/// 🔥 تحميل البيانات (مهم)
Future<void> loadFavorites() async {
  final prefs = await SharedPreferences.getInstance();

  final data = prefs.getStringList("favorites");

  if (data != null) {
    favoritePlaces = data.map<Place>((item) {
      final decoded = jsonDecode(item) as Map<String, dynamic>;
      final dynamic rawLat = decoded["lat"];
      final dynamic rawLng = decoded["lng"];
      final int id = (decoded["id"] is int)
          ? decoded["id"] as int
          : int.tryParse(decoded["id"]?.toString() ?? '') ?? 0;
      final String image = decoded["image"]?.toString() ?? '';
      final bool isAssetImage =
          decoded["isAssetImage"] is bool
              ? decoded["isAssetImage"] as bool
              : !(image.startsWith('http://') || image.startsWith('https://'));
      return Place(
        id: id,
        title: decoded["title"]?.toString() ?? '',
        subtitle: decoded["subtitle"]?.toString() ?? '',
        image: image,
        lat: (rawLat is num) ? rawLat.toDouble() : double.tryParse('$rawLat') ?? 0,
        lng: (rawLng is num) ? rawLng.toDouble() : double.tryParse('$rawLng') ?? 0,
        about: decoded["about"]?.toString() ??
            'This is a beautiful historical place in Egypt worth visiting...',
        isAssetImage: isAssetImage,
      );
    }).toList();
  }
}