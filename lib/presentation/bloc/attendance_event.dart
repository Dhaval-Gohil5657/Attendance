import 'package:equatable/equatable.dart';

abstract class AttendanceEvent extends Equatable {
  const AttendanceEvent();

  @override
  List<Object?> get props => [];
}

class InitializeAttendance extends AttendanceEvent {}

class CheckInEvent extends AttendanceEvent {
  final String employeeId;

  const CheckInEvent({required this.employeeId});

  @override
  List<Object?> get props => [employeeId];
}

class CheckOutEvent extends AttendanceEvent {}

class SyncNowEvent extends AttendanceEvent {
  final bool isManualSync;

  const SyncNowEvent({this.isManualSync = false});

  @override
  List<Object?> get props => [isManualSync];
}

class UpdateLocationDataEvent extends AttendanceEvent {
  final double latitude;
  final double longitude;

  const UpdateLocationDataEvent({
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [latitude, longitude];
}

class NetworkStatusChangedEvent extends AttendanceEvent {
  final bool isOnline;

  const NetworkStatusChangedEvent({required this.isOnline});

  @override
  List<Object?> get props => [isOnline];
}
