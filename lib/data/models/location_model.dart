import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';

import '../../domain/entities/location_entity.dart';
import '../datasource/local/database/app_database.dart';

class LocationModel extends LocationEntity {
  const LocationModel({
    super.id,
    required super.attendanceId,
    super.employeeId,
    required super.latitude,
    required super.longitude,
    required super.accuracy,
    required super.speed,
    required super.bearing,
    required super.altitude,
    required super.batteryLevel,
    required super.timestamp,
    super.isSynced = false,
  });

  factory LocationModel.fromEntity(LocationEntity entity) {
    return LocationModel(
      id: entity.id,
      attendanceId: entity.attendanceId,
      employeeId: entity.employeeId,
      latitude: entity.latitude,
      longitude: entity.longitude,
      accuracy: entity.accuracy,
      speed: entity.speed,
      bearing: entity.bearing,
      altitude: entity.altitude,
      batteryLevel: entity.batteryLevel,
      timestamp: entity.timestamp,
      isSynced: entity.isSynced,
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
