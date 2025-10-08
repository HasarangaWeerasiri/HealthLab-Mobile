import 'package:latlong2/latlong.dart';
import 'danger_zone.dart';

/// Represents an aggregated danger zone based on crowdsourced pins
class DangerZoneCluster {
  final LatLng center;
  final double radius; // in meters
  final List<DangerZone> pins;
  final DangerLevel aggregatedLevel;
  final int highCount;
  final int mediumCount;
  final int lowCount;

  DangerZoneCluster({
    required this.center,
    required this.radius,
    required this.pins,
    required this.aggregatedLevel,
    required this.highCount,
    required this.mediumCount,
    required this.lowCount,
  });

  /// Total number of pins in this cluster
  int get totalPins => pins.length;

  /// Percentage of high-risk pins
  double get highPercentage => totalPins > 0 ? (highCount / totalPins) * 100 : 0;

  /// Percentage of medium-risk pins
  double get mediumPercentage => totalPins > 0 ? (mediumCount / totalPins) * 100 : 0;

  /// Percentage of low-risk pins
  double get lowPercentage => totalPins > 0 ? (lowCount / totalPins) * 100 : 0;

  /// Creates a cluster from a list of nearby pins
  factory DangerZoneCluster.fromPins({
    required List<DangerZone> pins,
    required LatLng center,
    double radius = 200.0, // default 200 meters
  }) {
    if (pins.isEmpty) {
      return DangerZoneCluster(
        center: center,
        radius: radius,
        pins: [],
        aggregatedLevel: DangerLevel.low,
        highCount: 0,
        mediumCount: 0,
        lowCount: 0,
      );
    }

    // Count pins by danger level
    int highCount = pins.where((p) => p.dangerLevel == DangerLevel.high).length;
    int mediumCount = pins.where((p) => p.dangerLevel == DangerLevel.medium).length;
    int lowCount = pins.where((p) => p.dangerLevel == DangerLevel.low).length;

    // Determine aggregated level based on 60% threshold
    DangerLevel aggregatedLevel;
    final total = pins.length;
    final highPercentage = (highCount / total) * 100;
    final mediumPercentage = (mediumCount / total) * 100;

    if (highPercentage >= 60) {
      aggregatedLevel = DangerLevel.high;
    } else if (mediumPercentage >= 60) {
      aggregatedLevel = DangerLevel.medium;
    } else if (highPercentage > mediumPercentage && highPercentage > (lowCount / total) * 100) {
      aggregatedLevel = DangerLevel.high;
    } else if (mediumPercentage > (lowCount / total) * 100) {
      aggregatedLevel = DangerLevel.medium;
    } else {
      aggregatedLevel = DangerLevel.low;
    }

    return DangerZoneCluster(
      center: center,
      radius: radius,
      pins: pins,
      aggregatedLevel: aggregatedLevel,
      highCount: highCount,
      mediumCount: mediumCount,
      lowCount: lowCount,
    );
  }

  /// Gets a description of the cluster
  String get description {
    return '$totalPins reports: $highCount high, $mediumCount medium, $lowCount low';
  }
}
