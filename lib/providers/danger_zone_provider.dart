import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../models/danger_zone.dart';
import '../models/danger_zone_cluster.dart';
import '../services/storage_service.dart';
import '../services/location_service.dart';
import '../services/firebase_service.dart';
import '../services/clustering_service.dart';

/// Provider for managing danger zones state with Firebase sync
class DangerZoneProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  final LocationService _locationService = LocationService();
  final FirebaseService _firebaseService = FirebaseService();
  final ClusteringService _clusteringService = ClusteringService();

  List<DangerZone> _dangerZones = [];
  List<DangerZoneCluster> _clusters = [];
  LatLng? _currentLocation;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isOnline = true;
  StreamSubscription<List<DangerZone>>? _firebaseSubscription;
  
  Set<DangerLevel> _activeFilters = {
    DangerLevel.high,
    DangerLevel.medium,
    DangerLevel.low,
  };

  // Getters
  List<DangerZone> get dangerZones => _dangerZones;
  List<DangerZone> get filteredDangerZones => _dangerZones
      .where((zone) => _activeFilters.contains(zone.dangerLevel))
      .toList();
  List<DangerZoneCluster> get clusters => _clusters;
  List<DangerZoneCluster> get filteredClusters => _clusters
      .where((cluster) => _activeFilters.contains(cluster.aggregatedLevel))
      .toList();
  LatLng? get currentLocation => _currentLocation;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isOnline => _isOnline;
  Set<DangerLevel> get activeFilters => _activeFilters;

  /// Initializes the provider by loading saved zones and getting current location
  Future<void> initialize() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Get current location
      _currentLocation = await _locationService.getCurrentLocation();

      if (_currentLocation == null) {
        _errorMessage = 'Unable to get current location. Please enable location services.';
      }

      // Try to load from Firebase first
      if (_firebaseService.isAuthenticated) {
        _startFirebaseSync();
        _isOnline = true;
      } else {
        // Fallback to local storage
        _dangerZones = await _storageService.loadDangerZones();
        _isOnline = false;
      }

      // Generate clusters
      _updateClusters();
    } catch (e) {
      _errorMessage = 'Error initializing: $e';
      // Try loading from local storage as fallback
      _dangerZones = await _storageService.loadDangerZones();
      _isOnline = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Starts Firebase real-time sync
  void _startFirebaseSync() {
    _firebaseSubscription?.cancel();
    _firebaseSubscription = _firebaseService.streamDangerZones().listen(
      (zones) {
        _dangerZones = zones;
        _updateClusters();
        // Save to local storage for offline access
        _storageService.saveDangerZones(zones);
        notifyListeners();
      },
      onError: (error) {
        print('Firebase sync error: $error');
        _isOnline = false;
        notifyListeners();
      },
    );
  }

  /// Updates clusters based on current danger zones
  void _updateClusters() {
    _clusters = _clusteringService.clusterDangerZones(_dangerZones);
  }

  /// Adds a new danger zone
  Future<bool> addDangerZone({
    required LatLng position,
    required DangerLevel dangerLevel,
    String? description,
  }) async {
    try {
      final userId = _firebaseService.currentUserId ?? 'anonymous';
      final userName = _firebaseService.currentUserName;

      final newZone = DangerZone(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        latitude: position.latitude,
        longitude: position.longitude,
        dangerLevel: dangerLevel,
        createdAt: DateTime.now(),
        description: description,
        userId: userId,
        userName: userName,
        isSynced: false,
      );

      // Add to local list immediately
      _dangerZones.add(newZone);
      _updateClusters();
      notifyListeners();

      // Try to sync to Firebase
      if (_firebaseService.isAuthenticated) {
        final success = await _firebaseService.addDangerZone(newZone);
        if (success) {
          // Update sync status
          final index = _dangerZones.indexWhere((z) => z.id == newZone.id);
          if (index != -1) {
            _dangerZones[index] = newZone.copyWith(isSynced: true);
          }
          _isOnline = true;
        } else {
          _isOnline = false;
        }
      }

      // Always save to local storage
      await _storageService.saveDangerZones(_dangerZones);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error adding danger zone: $e';
      notifyListeners();
      return false;
    }
  }

  /// Updates an existing danger zone
  Future<bool> updateDangerZone({
    required String id,
    DangerLevel? dangerLevel,
    String? description,
  }) async {
    try {
      final index = _dangerZones.indexWhere((zone) => zone.id == id);
      if (index == -1) return false;

      _dangerZones[index] = _dangerZones[index].copyWith(
        dangerLevel: dangerLevel,
        description: description,
        isSynced: false,
      );

      _updateClusters();

      // Try to sync to Firebase
      if (_firebaseService.isAuthenticated) {
        await _firebaseService.updateDangerZone(_dangerZones[index]);
        _dangerZones[index] = _dangerZones[index].copyWith(isSynced: true);
      }

      await _storageService.saveDangerZones(_dangerZones);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error updating danger zone: $e';
      notifyListeners();
      return false;
    }
  }

  /// Deletes a danger zone
  Future<bool> deleteDangerZone(String id) async {
    try {
      // Try to delete from Firebase first
      if (_firebaseService.isAuthenticated) {
        await _firebaseService.deleteDangerZone(id);
      }

      _dangerZones.removeWhere((zone) => zone.id == id);
      _updateClusters();
      await _storageService.saveDangerZones(_dangerZones);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error deleting danger zone: $e';
      notifyListeners();
      return false;
    }
  }

  /// Toggles a danger level filter
  void toggleFilter(DangerLevel level) {
    if (_activeFilters.contains(level)) {
      _activeFilters.remove(level);
    } else {
      _activeFilters.add(level);
    }
    notifyListeners();
  }

  /// Refreshes the current location
  Future<void> refreshLocation() async {
    _currentLocation = await _locationService.getCurrentLocation();
    if (_currentLocation == null) {
      _errorMessage = 'Unable to get current location';
    }
    notifyListeners();
  }

  /// Clears all danger zones
  Future<bool> clearAllZones() async {
    try {
      _dangerZones.clear();
      await _storageService.clearDangerZones();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error clearing zones: $e';
      notifyListeners();
      return false;
    }
  }

  /// Syncs unsynced zones to Firebase
  Future<void> syncUnsyncedZones() async {
    if (!_firebaseService.isAuthenticated) return;

    final unsyncedZones = _dangerZones.where((z) => !z.isSynced).toList();
    if (unsyncedZones.isEmpty) return;

    final syncedIds = await _firebaseService.syncUnsyncedZones(unsyncedZones);

    // Update sync status for successfully synced zones
    for (final id in syncedIds) {
      final index = _dangerZones.indexWhere((z) => z.id == id);
      if (index != -1) {
        _dangerZones[index] = _dangerZones[index].copyWith(isSynced: true);
      }
    }

    if (syncedIds.isNotEmpty) {
      await _storageService.saveDangerZones(_dangerZones);
      _isOnline = true;
      notifyListeners();
    }
  }

  /// Clears the error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _firebaseSubscription?.cancel();
    super.dispose();
  }
}
