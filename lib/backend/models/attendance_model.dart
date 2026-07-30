import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import 'package:equatable/equatable.dart';

import '../../local/database/app_database.dart';

class AttendanceModel extends Equatable {
  final String attendanceId;
  final String employeeId;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final String status;
  final bool isTracking;
  final String travelMode; // 'Walking', 'Two-Wheeler', 'Four-Wheeler'
  final DateTime createdAt;

  const AttendanceModel({
    required this.attendanceId,
    required this.employeeId,
    required this.checkInTime,
    this.checkOutTime,
    required this.status,
    required this.isTracking,
    this.travelMode = 'Four-Wheeler',
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        attendanceId,
        employeeId,
        checkInTime,
        checkOutTime,
        status,
        isTracking,
        travelMode,
        createdAt,
      ];

  AttendanceModel copyWith({
    String? attendanceId,
    String? employeeId,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    String? status,
    bool? isTracking,
    String? travelMode,
    DateTime? createdAt,
  }) {
    return AttendanceModel(
      attendanceId: attendanceId ?? this.attendanceId,
      employeeId: employeeId ?? this.employeeId,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      status: status ?? this.status,
      isTracking: isTracking ?? this.isTracking,
      travelMode: travelMode ?? this.travelMode,
      createdAt: createdAt ?? this.createdAt,
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
      travelMode: data.travelMode,
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
      travelMode: Value(travelMode),
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
      'travelMode': travelMode,
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
      travelMode: json['travelMode'] ?? 'Four-Wheeler',
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }
}

typedef AttendanceEntity = AttendanceModel;
