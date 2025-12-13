import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache sencillo para datos JSON serializados.
class DataLocal {
  static Future<void> saveJson(String key, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(key, jsonEncode(data));
  }

  static Future<Map<String, dynamic>?> readJson(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove(key);
  }
}
