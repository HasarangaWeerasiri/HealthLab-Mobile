import 'package:latlong2/latlong.dart';

/// Enum representing the danger level of a zone
enum DangerLevel {
  high,
  medium,
  low;

  /// Returns the display name for the danger level
  String get displayName {
    switch (this) {
      case DangerLevel.high:
        return 'High';
      case DangerLevel.medium:
        return 'Medium';
      case DangerLevel.low:
        return 'Low';
    }
  }

  /// Returns the color code for the danger level
  String get colorCode {
    switch (this) {
      case DangerLevel.high:
        return 'red';
      case DangerLevel.medium:
        return 'yellow';
      case DangerLevel.low:
        return 'green';
    }
  }

  /// Returns the emoji for the danger level
  String get emoji {
    switch (this) {
      case DangerLevel.high:
        return '🟥';
      case DangerLevel.medium:
        return '🟨';
      case DangerLevel.low:
        return '🟩';
    }
  }
}

/// Model representing a danger zone marker on the map
class DangerZone {
  final String id;
  final double latitude;
  final double longitude;
  final DangerLevel dangerLevel;
  final DateTime createdAt;
  final String? description;
  final String userId; // User who created the pin
  final String? userName; // Optional user name
  final bool isSynced; // Whether synced to Firebase

  DangerZone({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.dangerLevel,
    required this.createdAt,
    this.description,
    required this.userId,
    this.userName,
    this.isSynced = true,
  });

  /// Converts the danger zone to a LatLng object for map display
  LatLng get position => LatLng(latitude, longitude);

  /// Converts the danger zone to a JSON map for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'dangerLevel': dangerLevel.name,
      'createdAt': createdAt.toIso8601String(),
      'description': description,
      'userId': userId,
      'userName': userName,
      'isSynced': isSynced,
    };
  }

  /// Converts to Firestore format (timestamp instead of ISO string)
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'dangerLevel': dangerLevel.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'description': description,
      'userId': userId,
      'userName': userName,
    };
  }

  /// Creates a danger zone from a JSON map
  factory DangerZone.fromJson(Map<String, dynamic> json) {
    return DangerZone(
      id: json['id'] as String,
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      dangerLevel: DangerLevel.values.firstWhere(
        (e) => e.name == json['dangerLevel'],
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      description: json['description'] as String?,
      userId: json['userId'] as String? ?? 'unknown',
      userName: json['userName'] as String?,
      isSynced: json['isSynced'] as bool? ?? true,
    );
  }

  /// Creates a danger zone from Firestore document
  factory DangerZone.fromFirestore(Map<String, dynamic> data) {
    return DangerZone(
      id: data['id'] as String,
      latitude: data['latitude'] as double,
      longitude: data['longitude'] as double,
      dangerLevel: DangerLevel.values.firstWhere(
        (e) => e.name == data['dangerLevel'],
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] as int),
      description: data['description'] as String?,
      userId: data['userId'] as String,
      userName: data['userName'] as String?,
      isSynced: true,
    );
  }

  /// Creates a copy of the danger zone with updated fields
  DangerZone copyWith({
    String? id,
    double? latitude,
    double? longitude,
    DangerLevel? dangerLevel,
    DateTime? createdAt,
    String? description,
    String? userId,
    String? userName,
    bool? isSynced,
  }) {
    return DangerZone(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      dangerLevel: dangerLevel ?? this.dangerLevel,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DangerZone && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
