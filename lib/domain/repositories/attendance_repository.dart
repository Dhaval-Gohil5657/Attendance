import '../entities/attendance_entity.dart';
import '../entities/location_entity.dart';

abstract class AttendanceRepository {
  Future<AttendanceEntity> checkIn({required String employeeId});
  Future<AttendanceEntity?> checkOut({required String attendanceId});
  Future<AttendanceEntity?> getActiveAttendance();
  Future<void> saveLocationRecord(LocationEntity location);
  Future<LocationEntity?> getLatestLocation();
  Future<int> getUnsyncedLocationsCount();
  Future<void> syncPendingData();
}
