import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

// -----------------------------------------------------------------------------
// Tables Definition
// -----------------------------------------------------------------------------

@DataClassName('AttendanceData')
class AttendanceTable extends Table {
  TextColumn get attendanceId => text()();
  TextColumn get employeeId => text()();
  DateTimeColumn get checkInTime => dateTime()();
  DateTimeColumn get checkOutTime => dateTime().nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  BoolColumn get isTracking => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {attendanceId};
}

@DataClassName('LocationLogData')
class LocationLogTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get attendanceId => text()();
  TextColumn get employeeId => text().nullable()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  RealColumn get accuracy => real().withDefault(const Constant(0.0))();
  RealColumn get speed => real().withDefault(const Constant(0.0))();
  RealColumn get bearing => real().withDefault(const Constant(0.0))();
  RealColumn get altitude => real().withDefault(const Constant(0.0))();
  IntColumn get batteryLevel => integer().withDefault(const Constant(0))();
  DateTimeColumn get timestamp => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
}

// -----------------------------------------------------------------------------
// Drift Database Class
// -----------------------------------------------------------------------------

@DriftDatabase(tables: [AttendanceTable, LocationLogTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // Attendance Queries
  Future<int> insertAttendance(AttendanceTableCompanion entry) =>
      into(attendanceTable).insert(entry, mode: InsertMode.insertOrReplace);

  Future<bool> updateAttendance(AttendanceTableCompanion entry) =>
      update(attendanceTable).replace(entry);

  Future<AttendanceData?> getActiveAttendance({String? employeeId}) {
    if (employeeId != null && employeeId.isNotEmpty) {
      return (select(attendanceTable)
            ..where((tbl) =>
                tbl.employeeId.equals(employeeId) &
                tbl.status.isIn(['active', 'on_break']) &
                tbl.checkOutTime.isNull())
            ..limit(1))
          .getSingleOrNull();
    }
    return (select(attendanceTable)
          ..where((tbl) =>
              tbl.status.isIn(['active', 'on_break']) &
              tbl.checkOutTime.isNull())
          ..limit(1))
        .getSingleOrNull();
  }

  Future<AttendanceData?> getAttendanceById(String id) {
    return (select(attendanceTable)
          ..where((tbl) => tbl.attendanceId.equals(id)))
        .getSingleOrNull();
  }

  // Location Queries
  Future<int> insertLocation(LocationLogTableCompanion entry) =>
      into(locationLogTable).insert(entry);

  Future<List<LocationLogData>> getUnsyncedLocations() {
    return (select(locationLogTable)
          ..where((tbl) => tbl.isSynced.equals(false)))
        .get();
  }

  Future<int> markLocationsAsSynced(List<int> ids) {
    return (update(locationLogTable)..where((tbl) => tbl.id.isIn(ids)))
        .write(const LocationLogTableCompanion(isSynced: Value(true)));
  }

  Future<LocationLogData?> getLatestLocation() {
    return (select(locationLogTable)
          ..orderBy([
            (tbl) => OrderingTerm(expression: tbl.timestamp, mode: OrderingMode.desc)
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<int> getUnsyncedCount() async {
    final unsynced = await getUnsyncedLocations();
    return unsynced.length;
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'attendance_app.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
