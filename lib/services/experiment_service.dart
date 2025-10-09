import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExperimentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> createExperiment({
    required String title,
    required String category,
    required List<String> emojis,
    required String description,
    required int durationDays,
    required List<Map<String, dynamic>> fields,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Not authenticated');
    }

    final docRef = _db.collection('experiments').doc();
    final data = {
      'title': title.trim(),
      'category': category,
      'emojis': emojis.take(3).toList(),
      'description': description.trim(),
      'durationDays': durationDays,
      'fields': fields.map((f) => _normalizeField(f)).toList(),
      'creatorId': currentUser.uid,
      'joinedCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'published': true,
    };

    await docRef.set(data);
    return docRef.id;
  }

  Map<String, dynamic> _normalizeField(Map<String, dynamic> field) {
    final type = field['type'];
    switch (type) {
      case 'slider':
        return {
          'type': 'slider',
          'title': field['title'] ?? '',
          'min': field['min'] ?? 0,
          'max': field['max'] ?? 10,
          'step': field['step'] ?? 1,
          'sequence': (field['sequence'] as List<dynamic>? ?? []).toList(),
        };
      case 'radio':
        return {
          'type': 'radio',
          'title': field['title'] ?? '',
          'options': (field['options'] as List<dynamic>? ?? ['Yes', 'No']).toList(),
        };
      case 'number':
      default:
        return {
          'type': 'number',
          'title': field['title'] ?? '',
          'unit': field['unit'] ?? '',
        };
    }
  }
}


