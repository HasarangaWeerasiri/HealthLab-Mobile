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

  // Get experiments created by the current user
  Future<List<Map<String, dynamic>>> getCreatedExperiments() async {
    final currentUser = _auth.currentUser;
    print('DEBUG: Current user: ${currentUser?.uid}');
    
    if (currentUser == null) {
      print('DEBUG: User not authenticated');
      throw Exception('Not authenticated');
    }

    try {
      print('DEBUG: Fetching created experiments for user: ${currentUser.uid}');
      
      // First get all experiments by creator, then filter and sort in memory
      final querySnapshot = await _db
          .collection('experiments')
          .where('creatorId', isEqualTo: currentUser.uid)
          .get();

      print('DEBUG: Found ${querySnapshot.docs.length} total experiments for user');

      final experiments = querySnapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            print('DEBUG: Experiment: ${data['title']}, published: ${data['published']}, deleted: ${data['deleted']}');
            return data;
          })
          .where((experiment) => experiment['published'] == true && experiment['deleted'] != true)
          .toList();

      print('DEBUG: Found ${experiments.length} published experiments');

      // Sort by createdAt in memory
      experiments.sort((a, b) {
        final aTime = a['createdAt'] as Timestamp?;
        final bTime = b['createdAt'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime); // Descending order
      });

      return experiments;
    } catch (e) {
      print('Error fetching created experiments: $e');
      return [];
    }
  }

  // Get experiments joined by the current user
  Future<List<Map<String, dynamic>>> getJoinedExperiments() async {
    final currentUser = _auth.currentUser;
    print('DEBUG: Getting joined experiments for user: ${currentUser?.uid}');
    
    if (currentUser == null) {
      print('DEBUG: User not authenticated for joined experiments');
      throw Exception('Not authenticated');
    }

    try {
      final joinedExperimentsSnapshot = await _db
          .collection('users')
          .doc(currentUser.uid)
          .collection('joinedExperiments')
          .get();

      print('DEBUG: Found ${joinedExperimentsSnapshot.docs.length} joined experiment references');

      if (joinedExperimentsSnapshot.docs.isEmpty) {
        print('DEBUG: No joined experiments found');
        return [];
      }

      // Get the actual experiment data for each joined experiment
      final List<Map<String, dynamic>> joinedExperiments = [];
      
      for (final doc in joinedExperimentsSnapshot.docs) {
        final experimentId = doc.id;
        final joinedData = doc.data();
        print('DEBUG: Processing joined experiment: $experimentId');
        
        try {
          final experimentDoc = await _db
              .collection('experiments')
              .doc(experimentId)
              .get();
          
          if (experimentDoc.exists) {
            final experimentData = experimentDoc.data()!;
            // Only add if experiment is not deleted
            if (experimentData['deleted'] != true) {
              experimentData['id'] = experimentId;
              experimentData['joinedAt'] = joinedData['joinedAt'];
              print('DEBUG: Added joined experiment: ${experimentData['title']}');
              joinedExperiments.add(experimentData);
            } else {
              print('DEBUG: Skipping deleted experiment: ${experimentData['title']}');
            }
          } else {
            print('DEBUG: Experiment $experimentId not found in experiments collection');
          }
        } catch (e) {
          print('Error fetching experiment $experimentId: $e');
          // Continue with other experiments
        }
      }

      print('DEBUG: Returning ${joinedExperiments.length} joined experiments');
      return joinedExperiments;
    } catch (e) {
      print('Error fetching joined experiments: $e');
      return [];
    }
  }

  // Get experiment by ID
  Future<Map<String, dynamic>?> getExperimentById(String experimentId) async {
    try {
      final doc = await _db.collection('experiments').doc(experimentId).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      print('Error fetching experiment: $e');
      return null;
    }
  }

  // Check if user has joined an experiment
  Future<bool> hasUserJoinedExperiment(String experimentId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      final doc = await _db
          .collection('users')
          .doc(currentUser.uid)
          .collection('joinedExperiments')
          .doc(experimentId)
          .get();
      
      return doc.exists;
    } catch (e) {
      print('Error checking if user joined experiment: $e');
      return false;
    }
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


