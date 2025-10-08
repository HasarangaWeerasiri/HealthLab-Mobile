import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/danger_zone.dart';

/// Service for handling local storage of danger zones
class StorageService {
  static const String _dangerZonesKey = 'danger_zones';

  /// Saves a list of danger zones to local storage
  Future<bool> saveDangerZones(List<DangerZone> zones) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = zones.map((zone) => zone.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      return await prefs.setString(_dangerZonesKey, jsonString);
    } catch (e) {
      print('Error saving danger zones: $e');
      return false;
    }
  }

  /// Loads the list of danger zones from local storage
  Future<List<DangerZone>> loadDangerZones() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_dangerZonesKey);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => DangerZone.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading danger zones: $e');
      return [];
    }
  }

  /// Clears all danger zones from local storage
  Future<bool> clearDangerZones() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_dangerZonesKey);
    } catch (e) {
      print('Error clearing danger zones: $e');
      return false;
    }
  }
}
