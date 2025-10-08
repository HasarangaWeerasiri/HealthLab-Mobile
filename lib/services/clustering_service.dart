import 'dart:math' as math;
import 'package:latlong2/latlong.dart';
import '../models/danger_zone.dart';
import '../models/danger_zone_cluster.dart';

/// Service for clustering nearby danger zones and calculating aggregated risk levels
class ClusteringService {
  static const double defaultClusterRadius = 200.0; // meters

  /// Groups danger zones into clusters based on proximity
  List<DangerZoneCluster> clusterDangerZones(
    List<DangerZone> zones, {
    double clusterRadius = defaultClusterRadius,
  }) {
    if (zones.isEmpty) return [];

    final List<DangerZoneCluster> clusters = [];
    final List<DangerZone> processedZones = [];

    for (final zone in zones) {
      if (processedZones.contains(zone)) continue;

      // Find all zones within cluster radius
      final nearbyZones = zones.where((z) {
        if (processedZones.contains(z)) return false;
        final distance = _calculateDistance(
          zone.latitude,
          zone.longitude,
          z.latitude,
          z.longitude,
        );
        return distance <= clusterRadius;
      }).toList();

      if (nearbyZones.isEmpty) continue;

      // Calculate cluster center (average position)
      final centerLat = nearbyZones.map((z) => z.latitude).reduce((a, b) => a + b) /
          nearbyZones.length;
      final centerLon = nearbyZones.map((z) => z.longitude).reduce((a, b) => a + b) /
          nearbyZones.length;

      // Create cluster
      final cluster = DangerZoneCluster.fromPins(
        pins: nearbyZones,
        center: LatLng(centerLat, centerLon),
        radius: clusterRadius,
      );

      clusters.add(cluster);
      processedZones.addAll(nearbyZones);
    }

    return clusters;
  }

  /// Gets clusters visible in the current map view
  List<DangerZoneCluster> getClustersInView({
    required List<DangerZone> allZones,
    required LatLng mapCenter,
    required double mapZoom,
    double clusterRadius = defaultClusterRadius,
  }) {
    // Calculate visible radius based on zoom level
    final visibleRadius = _getVisibleRadius(mapZoom);

    // Filter zones within visible area
    final visibleZones = allZones.where((zone) {
      final distance = _calculateDistance(
        mapCenter.latitude,
        mapCenter.longitude,
        zone.latitude,
        zone.longitude,
      );
      return distance <= visibleRadius;
    }).toList();

    // Cluster the visible zones
    return clusterDangerZones(visibleZones, clusterRadius: clusterRadius);
  }

  /// Calculates the visible radius based on zoom level
  double _getVisibleRadius(double zoom) {
    // Approximate visible radius in meters based on zoom
    // Higher zoom = smaller visible area
    return 40075000 / math.pow(2, zoom + 1); // Earth's circumference / 2^(zoom+1)
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

  /// Finds the cluster containing a specific zone
  DangerZoneCluster? findClusterForZone(
    DangerZone zone,
    List<DangerZoneCluster> clusters,
  ) {
    for (final cluster in clusters) {
      if (cluster.pins.any((p) => p.id == zone.id)) {
        return cluster;
      }
    }
    return null;
  }

  /// Gets zones near a specific point
  List<DangerZone> getZonesNearPoint({
    required List<DangerZone> allZones,
    required LatLng point,
    double radius = defaultClusterRadius,
  }) {
    return allZones.where((zone) {
      final distance = _calculateDistance(
        point.latitude,
        point.longitude,
        zone.latitude,
        zone.longitude,
      );
      return distance <= radius;
    }).toList();
  }
}
