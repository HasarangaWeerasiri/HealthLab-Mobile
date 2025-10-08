import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/danger_zone.dart';

/// Service for handling Firebase Firestore operations for danger zones
class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _collectionName = 'danger_zones';

  /// Gets the current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Gets the current user name
  String? get currentUserName => _auth.currentUser?.displayName;

  /// Adds a danger zone to Firestore
  Future<bool> addDangerZone(DangerZone zone) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(zone.id)
          .set(zone.toFirestore());
      return true;
    } catch (e) {
      print('Error adding danger zone to Firestore: $e');
      return false;
    }
  }

  /// Updates a danger zone in Firestore
  Future<bool> updateDangerZone(DangerZone zone) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(zone.id)
          .update(zone.toFirestore());
      return true;
    } catch (e) {
      print('Error updating danger zone in Firestore: $e');
      return false;
    }
  }

  /// Deletes a danger zone from Firestore
  Future<bool> deleteDangerZone(String zoneId) async {
    try {
      await _firestore.collection(_collectionName).doc(zoneId).delete();
      return true;
    } catch (e) {
      print('Error deleting danger zone from Firestore: $e');
      return false;
    }
  }

  /// Gets all danger zones from Firestore (one-time fetch)
  Future<List<DangerZone>> getAllDangerZones() async {
    try {
      final snapshot = await _firestore.collection(_collectionName).get();
      return snapshot.docs
          .map((doc) => DangerZone.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching danger zones from Firestore: $e');
      return [];
    }
  }

  /// Streams all danger zones in real-time
  Stream<List<DangerZone>> streamDangerZones() {
    return _firestore.collection(_collectionName).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => DangerZone.fromFirestore(doc.data()))
              .toList(),
        );
  }

  /// Gets danger zones within a specific radius (in meters) from a point
  Future<List<DangerZone>> getDangerZonesNearby({
    required double latitude,
    required double longitude,
    double radiusInMeters = 1000.0,
  }) async {
    try {
      // Approximate degree offset for the radius
      // 1 degree latitude ≈ 111km
      final latOffset = radiusInMeters / 111000;
      final lonOffset = radiusInMeters / (111000 * 0.9); // Approximate for mid-latitudes

      final snapshot = await _firestore
          .collection(_collectionName)
          .where('latitude', isGreaterThan: latitude - latOffset)
          .where('latitude', isLessThan: latitude + latOffset)
          .get();

      // Filter by longitude and calculate actual distance
      final zones = snapshot.docs
          .map((doc) => DangerZone.fromFirestore(doc.data()))
          .where((zone) {
        final distance = _calculateDistance(
          latitude,
          longitude,
          zone.latitude,
          zone.longitude,
        );
        return distance <= radiusInMeters;
      }).toList();

      return zones;
    } catch (e) {
      print('Error fetching nearby danger zones: $e');
      return [];
    }
  }

  /// Calculates distance between two points in meters (Haversine formula)
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000; // meters
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }

  /// Syncs unsynced local zones to Firestore
  Future<List<String>> syncUnsyncedZones(List<DangerZone> unsyncedZones) async {
    final syncedIds = <String>[];

    for (final zone in unsyncedZones) {
      final success = await addDangerZone(zone);
      if (success) {
        syncedIds.add(zone.id);
      }
    }

    return syncedIds;
  }

  /// Checks if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;

  /// Gets user-specific danger zones
  Future<List<DangerZone>> getUserDangerZones(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .get();

      return snapshot.docs
          .map((doc) => DangerZone.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching user danger zones: $e');
      return [];
    }
  }
}
