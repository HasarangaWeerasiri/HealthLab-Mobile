import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';

class CsvExportService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Export experiment data to CSV file
  Future<String?> exportExperimentData(String experimentId) async {
    try {
      print('DEBUG: Starting CSV export for experiment: $experimentId');
      
      // Get experiment details
      final experimentDoc = await _db.collection('experiments').doc(experimentId).get();
      if (!experimentDoc.exists) {
        throw Exception('Experiment not found');
      }
      
      print('DEBUG: Found experiment: ${experimentDoc.data()?['title']}');

      final experimentData = experimentDoc.data()!;
      final experimentTitle = experimentData['title'] ?? 'Untitled Experiment';
      final fields = (experimentData['fields'] as List<dynamic>? ?? [])
          .map((f) => Map<String, dynamic>.from(f))
          .toList();

      // Get all users who joined this experiment
      // We need to search through all users' joinedExperiments subcollections
      final usersSnapshot = await _db.collection('users').get();
      final List<DocumentSnapshot> joinedUsersDocs = [];
      
      for (final userDoc in usersSnapshot.docs) {
        final joinedDoc = await _db
            .collection('users')
            .doc(userDoc.id)
            .collection('joinedExperiments')
            .doc(experimentId)
            .get();
        
        if (joinedDoc.exists) {
          joinedUsersDocs.add(joinedDoc);
        }
      }

      print('DEBUG: Found ${joinedUsersDocs.length} participants');
      
      if (joinedUsersDocs.isEmpty) {
        throw Exception('No participants found for this experiment');
      }

      // Prepare CSV data
      final List<List<dynamic>> csvData = [];
      
      // Create header row
      final headerRow = [
        'User ID',
        'User Email',
        'Joined Date',
        'Entry Date',
        'Day Index',
        ...fields.map((field) => field['title'] ?? 'Unknown Field'),
      ];
      csvData.add(headerRow);

      // Process each participant
      for (final joinedDoc in joinedUsersDocs) {
        final userId = joinedDoc.reference.parent.parent?.id;
        if (userId == null) continue;

        // Get user details
        final userDoc = await _db.collection('users').doc(userId).get();
        final userEmail = userDoc.data()?['email'] ?? 'Unknown';
        final joinedData = joinedDoc.data() as Map<String, dynamic>?;
        final joinedAt = (joinedData?['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now();

        // Get user's entries for this experiment
        final entriesSnapshot = await _db
            .collection('users')
            .doc(userId)
            .collection('joinedExperiments')
            .doc(experimentId)
            .collection('dailyEntries')
            .orderBy('createdAt', descending: false)
            .get();

        if (entriesSnapshot.docs.isEmpty) {
          // Add row for user with no entries
          final row = [
            userId,
            userEmail,
            joinedAt.toIso8601String().split('T')[0], // Date only
            'No entries',
            'N/A',
            ...List.filled(fields.length, 'N/A'),
          ];
          csvData.add(row);
        } else {
          // Add row for each entry
          for (final entryDoc in entriesSnapshot.docs) {
            final entryData = entryDoc.data();
            final entryDate = (entryData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
            final dayIndex = entryData['dayIndex'] ?? 'N/A';
            final values = entryData['values'] as Map<String, dynamic>? ?? {};

            final row = [
              userId,
              userEmail,
              joinedAt.toIso8601String().split('T')[0], // Date only
              entryDate.toIso8601String().split('T')[0], // Date only
              dayIndex.toString(),
              ...fields.map((field) {
                final fieldTitle = field['title'] ?? 'Unknown Field';
                return values[fieldTitle]?.toString() ?? 'N/A';
              }),
            ];
            csvData.add(row);
          }
        }
      }

      // Generate CSV string
      print('DEBUG: Generating CSV with ${csvData.length} rows');
      final csvString = const ListToCsvConverter().convert(csvData);

      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${experimentTitle.replaceAll(RegExp(r'[^\w\s-]'), '')}_export_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csvString);
      
      print('DEBUG: CSV file saved to: ${file.path}');
      
      // Return user-friendly path information
      return '${directory.path}/$fileName';
    } catch (e) {
      print('Error exporting experiment data: $e');
      print('Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  /// Share CSV file (for mobile platforms)
  Future<void> shareCsvFile(String filePath) async {
    try {
      // This would typically use a share plugin like share_plus
      // For now, we'll just copy to clipboard and show a message
      final file = File(filePath);
      final content = await file.readAsString();
      
      await Clipboard.setData(ClipboardData(text: content));
      
      // In a real implementation, you would use:
      // await Share.shareXFiles([XFile(filePath)], text: 'Experiment data export');
    } catch (e) {
      print('Error sharing CSV file: $e');
    }
  }

  /// Get user-friendly directory description
  String getUserFriendlyDirectoryDescription() {
    // This provides a general description since the exact path varies by platform
    return 'App Documents Folder';
  }

  /// Get experiment statistics for preview
  Future<Map<String, dynamic>> getExperimentStats(String experimentId) async {
    try {
      // Get experiment details
      final experimentDoc = await _db.collection('experiments').doc(experimentId).get();
      if (!experimentDoc.exists) {
        throw Exception('Experiment not found');
      }

      final experimentData = experimentDoc.data()!;
      final experimentTitle = experimentData['title'] ?? 'Untitled Experiment';

      // Get all users who joined this experiment
      // We need to search through all users' joinedExperiments subcollections
      final usersSnapshot = await _db.collection('users').get();
      final List<DocumentSnapshot> joinedUsersDocs = [];
      
      for (final userDoc in usersSnapshot.docs) {
        final joinedDoc = await _db
            .collection('users')
            .doc(userDoc.id)
            .collection('joinedExperiments')
            .doc(experimentId)
            .get();
        
        if (joinedDoc.exists) {
          joinedUsersDocs.add(joinedDoc);
        }
      }

      int totalParticipants = joinedUsersDocs.length;
      int totalEntries = 0;
      int activeParticipants = 0;

      // Count entries and active participants
      for (final joinedDoc in joinedUsersDocs) {
        final userId = joinedDoc.reference.parent.parent?.id;
        if (userId == null) continue;

        final entriesSnapshot = await _db
            .collection('users')
            .doc(userId)
            .collection('joinedExperiments')
            .doc(experimentId)
            .collection('dailyEntries')
            .get();

        final userEntryCount = entriesSnapshot.docs.length;
        totalEntries += userEntryCount;
        
        if (userEntryCount > 0) {
          activeParticipants++;
        }
      }

      return {
        'title': experimentTitle,
        'totalParticipants': totalParticipants,
        'activeParticipants': activeParticipants,
        'totalEntries': totalEntries,
        'averageEntriesPerParticipant': totalParticipants > 0 ? (totalEntries / totalParticipants).toStringAsFixed(1) : '0',
      };
    } catch (e) {
      print('Error getting experiment stats: $e');
      return {
        'title': 'Unknown',
        'totalParticipants': 0,
        'activeParticipants': 0,
        'totalEntries': 0,
        'averageEntriesPerParticipant': '0',
      };
    }
  }
}
