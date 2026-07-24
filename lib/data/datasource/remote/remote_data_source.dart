import '../../models/attendance_model.dart';
import '../../models/location_model.dart';

abstract class RemoteDataSource {
  Future<void> syncAttendance(AttendanceModel attendance);
  Future<void> syncLocations(List<LocationModel> locations);
  Future<String?> getCurrentUserId();
}
