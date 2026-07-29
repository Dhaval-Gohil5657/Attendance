import '../entities/attendance_entity.dart';
import '../entities/location_entity.dart';

abstract class AttendanceRepository {
  Future<AttendanceEntity> checkIn({
    required String employeeId,
    String travelMode = 'Four-Wheeler',
  });
  Future<AttendanceEntity?> checkOut({required String attendanceId});
  Future<AttendanceEntity?> startBreak({required String attendanceId});
  Future<AttendanceEntity?> endBreak({required String attendanceId});
  Future<AttendanceEntity?> getActiveAttendance({String? employeeId});
  Future<void> saveLocationRecord(LocationEntity location);
  Future<LocationEntity?> getLatestLocation();
  Future<int> getUnsyncedLocationsCount();
  Future<void> syncPendingData();
}
