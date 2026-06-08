import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SaveManager {
  static const String saveKey = 'collor_save';

  static Future<void> save(Map<String, dynamic> gameData) async {
    final prefs = await SharedPreferences.getInstance();
    String jsonString = jsonEncode(gameData);
    await prefs.setString(saveKey, jsonString);
  }

  static Future<Map<String, dynamic>?> load() async {
    final prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString(saveKey);
    if (jsonString != null) {
      try {
        return jsonDecode(jsonString);
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}
