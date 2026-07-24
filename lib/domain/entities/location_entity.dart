import 'package:equatable/equatable.dart';

class LocationEntity extends Equatable {
  final int? id;
  final String attendanceId;
  final double latitude;
  final double longitude;
  final double accuracy;
  final double speed;
  final double bearing;
  final double altitude;
  final int batteryLevel;
  final DateTime timestamp;
  final bool isSynced;

  const LocationEntity({
    this.id,
    required this.attendanceId,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.speed,
    required this.bearing,
    required this.altitude,
    required this.batteryLevel,
    required this.timestamp,
    this.isSynced = false,
  });

  @override
  List<Object?> get props => [
        id,
        attendanceId,
        latitude,
        longitude,
        accuracy,
        speed,
        bearing,
        altitude,
        batteryLevel,
        timestamp,
        isSynced,
      ];

  LocationEntity copyWith({
    int? id,
    String? attendanceId,
    double? latitude,
    double? longitude,
    double? accuracy,
    double? speed,
    double? bearing,
    double? altitude,
    int? batteryLevel,
    DateTime? timestamp,
    bool? isSynced,
  }) {
    return LocationEntity(
      id: id ?? this.id,
      attendanceId: attendanceId ?? this.attendanceId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      speed: speed ?? this.speed,
      bearing: bearing ?? this.bearing,
      altitude: altitude ?? this.altitude,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      timestamp: timestamp ?? this.timestamp,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
