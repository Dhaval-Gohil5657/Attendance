import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';

import '../../domain/entities/attendance_entity.dart';
import '../datasource/local/database/app_database.dart';

class AttendanceModel extends AttendanceEntity {
  const AttendanceModel({
    required super.attendanceId,
    required super.employeeId,
    required super.checkInTime,
    super.checkOutTime,
    required super.status,
    required super.isTracking,
    required super.createdAt,
  });

  factory AttendanceModel.fromEntity(AttendanceEntity entity) {
    return AttendanceModel(
      attendanceId: entity.attendanceId,
      employeeId: entity.employeeId,
      checkInTime: entity.checkInTime,
      checkOutTime: entity.checkOutTime,
      status: entity.status,
      isTracking: entity.isTracking,
      createdAt: entity.createdAt,
    );
  }

  factory AttendanceModel.fromDrift(AttendanceData data) {
    return AttendanceModel(
      attendanceId: data.attendanceId,
      employeeId: data.employeeId,
      checkInTime: data.checkInTime,
      checkOutTime: data.checkOutTime,
      status: data.status,
      isTracking: data.isTracking,
      createdAt: data.createdAt,
    );
  }

  AttendanceTableCompanion toDriftCompanion() {
    return AttendanceTableCompanion.insert(
      attendanceId: attendanceId,
      employeeId: employeeId,
      checkInTime: checkInTime,
      checkOutTime: Value(checkOutTime),
      status: Value(status),
      isTracking: Value(isTracking),
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'attendanceId': attendanceId,
      'employeeId': employeeId,
      'checkInTime': Timestamp.fromDate(checkInTime),
      'checkOutTime': checkOutTime != null ? Timestamp.fromDate(checkOutTime!) : null,
      'status': status,
      'isTracking': isTracking,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory AttendanceModel.fromFirestore(Map<String, dynamic> json) {
    return AttendanceModel(
      attendanceId: json['attendanceId'] ?? '',
      employeeId: json['employeeId'] ?? '',
      checkInTime: (json['checkInTime'] as Timestamp).toDate(),
      checkOutTime: json['checkOutTime'] != null
          ? (json['checkOutTime'] as Timestamp).toDate()
          : null,
      status: json['status'] ?? 'active',
      isTracking: json['isTracking'] ?? false,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }
}
