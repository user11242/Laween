import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WallpaperProvider extends ChangeNotifier {
  static const String _prefKey = 'group_wallpapers_map';
  SharedPreferences? _prefs;

  // Custom Map: GroupId -> Wallpaper String (hex or path)
  final Map<String, String> _wallpapers = {};

  WallpaperProvider() {
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    final String? jsonString = _prefs?.getString(_prefKey);

    if (jsonString != null) {
      try {
        final Map<String, dynamic> decodedMap = jsonDecode(jsonString);
        decodedMap.forEach((key, value) {
          if (value is String) {
            _wallpapers[key] = value;
          }
        });
      } catch (e) {
        debugPrint("Error decoding wallpaper map: $e");
      }
    }
    notifyListeners();
  }

  String? getWallpaper(String groupId) {
    return _wallpapers[groupId];
  }

  Future<void> setWallpaper(String groupId, String wallpaperString) async {
    _wallpapers[groupId] = wallpaperString;
    notifyListeners();
    await _saveToPrefs();
  }

  Future<void> clearWallpaper(String groupId) async {
    if (_wallpapers.containsKey(groupId)) {
      _wallpapers.remove(groupId);
      notifyListeners();
      await _saveToPrefs();
    }
  }

  Future<void> _saveToPrefs() async {
    if (_prefs != null) {
      final jsonString = jsonEncode(_wallpapers);
      await _prefs!.setString(_prefKey, jsonString);
    }
  }
}
