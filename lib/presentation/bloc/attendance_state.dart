import 'package:equatable/equatable.dart';

import '../../domain/entities/attendance_entity.dart';

class AttendanceState extends Equatable {
  final bool isLoading;
  final AttendanceEntity? activeAttendance;
  final double? currentLatitude;
  final double? currentLongitude;
  final int unsyncedCount;
  final bool isOnline;
  final String? errorMessage;
  final String? successMessage;

  const AttendanceState({
    this.isLoading = false,
    this.activeAttendance,
    this.currentLatitude,
    this.currentLongitude,
    this.unsyncedCount = 0,
    this.isOnline = true,
    this.errorMessage,
    this.successMessage,
  });

  AttendanceState copyWith({
    bool? isLoading,
    AttendanceEntity? Function()? activeAttendance,
    double? Function()? currentLatitude,
    double? Function()? currentLongitude,
    int? unsyncedCount,
    bool? isOnline,
    String? Function()? errorMessage,
    String? Function()? successMessage,
  }) {
    return AttendanceState(
      isLoading: isLoading ?? this.isLoading,
      activeAttendance:
          activeAttendance != null ? activeAttendance() : this.activeAttendance,
      currentLatitude:
          currentLatitude != null ? currentLatitude() : this.currentLatitude,
      currentLongitude:
          currentLongitude != null ? currentLongitude() : this.currentLongitude,
      unsyncedCount: unsyncedCount ?? this.unsyncedCount,
      isOnline: isOnline ?? this.isOnline,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      successMessage:
          successMessage != null ? successMessage() : this.successMessage,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        activeAttendance,
        currentLatitude,
        currentLongitude,
        unsyncedCount,
        isOnline,
        errorMessage,
        successMessage,
      ];
}
