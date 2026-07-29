import 'package:equatable/equatable.dart';

class AttendanceEntity extends Equatable {
  final String attendanceId;
  final String employeeId;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final String status;
  final bool isTracking;
  final String travelMode; // 'Walking', 'Two-Wheeler', 'Four-Wheeler'
  final DateTime createdAt;

  const AttendanceEntity({
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

  AttendanceEntity copyWith({
    String? attendanceId,
    String? employeeId,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    String? status,
    bool? isTracking,
    String? travelMode,
    DateTime? createdAt,
  }) {
    return AttendanceEntity(
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
}
