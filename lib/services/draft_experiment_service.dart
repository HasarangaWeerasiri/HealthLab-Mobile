import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DraftExperimentService {
  static const String _draftsKey = 'experiment_drafts_v1';

  Future<List<Map<String, dynamic>>> getDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_draftsKey);
    if (raw == null || raw.isEmpty) return [];
    final List<dynamic> list = jsonDecode(raw);
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> upsertDraft(Map<String, dynamic> draft) async {
    final prefs = await SharedPreferences.getInstance();
    final drafts = await getDrafts();
    final id = draft['id'] as String? ?? _generateId();
    draft['id'] = id;
    draft['updatedAt'] = DateTime.now().toIso8601String();

    final index = drafts.indexWhere((d) => d['id'] == id);
    if (index >= 0) {
      drafts[index] = draft;
    } else {
      drafts.add(draft);
    }
    await prefs.setString(_draftsKey, jsonEncode(drafts));
  }

  Future<void> removeDraft(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final drafts = await getDrafts();
    drafts.removeWhere((d) => d['id'] == id);
    await prefs.setString(_draftsKey, jsonEncode(drafts));
  }

  String _generateId() => DateTime.now().millisecondsSinceEpoch.toString();
}


