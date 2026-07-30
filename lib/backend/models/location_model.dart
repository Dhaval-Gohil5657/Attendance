import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import 'package:equatable/equatable.dart';

import '../../local/database/app_database.dart';

class LocationModel extends Equatable {
  final int? id;
  final String attendanceId;
  final String? employeeId;
  final double latitude;
  final double longitude;
  final double accuracy;
  final double speed;
  final double bearing;
  final double altitude;
  final int batteryLevel;
  final DateTime timestamp;
  final bool isSynced;

  const LocationModel({
    this.id,
    required this.attendanceId,
    this.employeeId,
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
        employeeId,
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

  LocationModel copyWith({
    int? id,
    String? attendanceId,
    String? employeeId,
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
    return LocationModel(
      id: id ?? this.id,
      attendanceId: attendanceId ?? this.attendanceId,
      employeeId: employeeId ?? this.employeeId,
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

  factory LocationModel.fromDrift(LocationLogData data) {
    return LocationModel(
      id: data.id,
      attendanceId: data.attendanceId,
      employeeId: data.employeeId,
      latitude: data.latitude,
      longitude: data.longitude,
      accuracy: data.accuracy,
      speed: data.speed,
      bearing: data.bearing,
      altitude: data.altitude,
      batteryLevel: data.batteryLevel,
      timestamp: data.timestamp,
      isSynced: data.isSynced,
    );
  }

  LocationLogTableCompanion toDriftCompanion() {
    return LocationLogTableCompanion.insert(
      attendanceId: attendanceId,
      employeeId: Value(employeeId),
      latitude: latitude,
      longitude: longitude,
      accuracy: Value(accuracy),
      speed: Value(speed),
      bearing: Value(bearing),
      altitude: Value(altitude),
      batteryLevel: Value(batteryLevel),
      timestamp: timestamp,
      isSynced: Value(isSynced),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'attendanceId': attendanceId,
      'employeeId': employeeId ?? '',
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'speed': speed,
      'bearing': bearing,
      'altitude': altitude,
      'batteryLevel': batteryLevel,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory LocationModel.fromFirestore(Map<String, dynamic> json, {int? id}) {
    return LocationModel(
      id: id,
      attendanceId: json['attendanceId'] ?? '',
      employeeId: json['employeeId'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracy: (json['accuracy'] as num).toDouble(),
      speed: (json['speed'] as num).toDouble(),
      bearing: (json['bearing'] as num).toDouble(),
      altitude: (json['altitude'] as num).toDouble(),
      batteryLevel: (json['batteryLevel'] as num).toInt(),
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      isSynced: true,
    );
  }
}

typedef LocationEntity = LocationModel;
