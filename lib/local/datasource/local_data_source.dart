import '../../backend/models/attendance_model.dart';
import '../../backend/models/location_model.dart';
import '../database/app_database.dart';

abstract class LocalDataSource {
  Future<void> saveAttendance(AttendanceModel attendance);
  Future<AttendanceModel?> getActiveAttendance({String? employeeId});
  Future<AttendanceModel?> getAttendanceById(String id);
  Future<void> saveLocation(LocationModel location);
  Future<List<LocationModel>> getUnsyncedLocations();
  Future<void> markLocationsAsSynced(List<int> ids);
  Future<LocationModel?> getLatestLocation();
  Future<int> getUnsyncedCount();
}

class LocalDataSourceImpl implements LocalDataSource {
  final AppDatabase database;

  LocalDataSourceImpl({required this.database});

  @override
  Future<void> saveAttendance(AttendanceModel attendance) async {
    await database.insertAttendance(attendance.toDriftCompanion());
  }

  @override
  Future<AttendanceModel?> getActiveAttendance({String? employeeId}) async {
    final activeData = await database.getActiveAttendance(employeeId: employeeId);
    if (activeData != null) {
      return AttendanceModel.fromDrift(activeData);
    }
    if (employeeId != null && employeeId.isNotEmpty) {
      final todayData = await database.getLatestAttendanceToday(employeeId: employeeId);
      if (todayData != null) {
        return AttendanceModel.fromDrift(todayData);
      }
    }
    return null;
  }

  @override
  Future<AttendanceModel?> getAttendanceById(String id) async {
    final data = await database.getAttendanceById(id);
    if (data == null) return null;
    return AttendanceModel.fromDrift(data);
  }

  @override
  Future<void> saveLocation(LocationModel location) async {
    await database.insertLocation(location.toDriftCompanion());
  }

  @override
  Future<List<LocationModel>> getUnsyncedLocations() async {
    final dataList = await database.getUnsyncedLocations();
    return dataList.map((e) => LocationModel.fromDrift(e)).toList();
  }

  @override
  Future<void> markLocationsAsSynced(List<int> ids) async {
    if (ids.isEmpty) return;
    await database.markLocationsAsSynced(ids);
  }

  @override
  Future<LocationModel?> getLatestLocation() async {
    final data = await database.getLatestLocation();
    if (data == null) return null;
    return LocationModel.fromDrift(data);
  }

  @override
  Future<int> getUnsyncedCount() async {
    return await database.getUnsyncedCount();
  }
}
