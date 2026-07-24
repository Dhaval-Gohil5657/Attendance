import 'package:equatable/equatable.dart';

class AttendanceEntity extends Equatable {
  final String attendanceId;
  final String employeeId;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final String status;
  final bool isTracking;
  final DateTime createdAt;

  const AttendanceEntity({
    required this.attendanceId,
    required this.employeeId,
    required this.checkInTime,
    this.checkOutTime,
    required this.status,
    required this.isTracking,
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
        createdAt,
      ];

  AttendanceEntity copyWith({
    String? attendanceId,
    String? employeeId,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    String? status,
    bool? isTracking,
    DateTime? createdAt,
  }) {
    return AttendanceEntity(
      attendanceId: attendanceId ?? this.attendanceId,
      employeeId: employeeId ?? this.employeeId,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      status: status ?? this.status,
      isTracking: isTracking ?? this.isTracking,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
