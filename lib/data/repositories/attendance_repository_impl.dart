import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/attendance_entity.dart';
import '../../domain/entities/location_entity.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../datasource/local/local_data_source.dart';
import '../datasource/remote/remote_data_source.dart';
import '../models/attendance_model.dart';
import '../models/location_model.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final LocalDataSource localDataSource;
  final RemoteDataSource remoteDataSource;
  final Connectivity connectivity;
  final Logger logger = Logger();
  final Uuid uuid = const Uuid();

  AttendanceRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.connectivity,
  });

  @override
  Future<AttendanceEntity> checkIn({required String employeeId}) async {
    final now = DateTime.now();
    final attendanceId = uuid.v4();

    final model = AttendanceModel(
      attendanceId: attendanceId,
      employeeId: employeeId,
      checkInTime: now,
      status: 'active',
      isTracking: true,
      createdAt: now,
    );

    // Save locally first (Source of Truth)
    await localDataSource.saveAttendance(model);
    logger.i('Attendance check-in saved locally: $attendanceId');

    // Try sync with Remote/Firebase if network is available
    final connectivityResult = await connectivity.checkConnectivity();
    if (_hasNetworkConnection(connectivityResult)) {
      try {
        await remoteDataSource.syncAttendance(model);
        logger.i('Attendance check-in synced to Firebase immediately.');
      } catch (e) {
        logger.w('Failed immediate sync of check-in, queued for later auto-sync: $e');
      }
    }

    // Capture and save initial location point immediately
    try {
      final isGpsEnabled = await Geolocator.isLocationServiceEnabled();
      if (isGpsEnabled) {
        Position? initialPos = await Geolocator.getLastKnownPosition();
        initialPos ??= await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 4),
          ),
        );

        final initialLocEntity = LocationEntity(
          attendanceId: attendanceId,
          latitude: initialPos.latitude,
          longitude: initialPos.longitude,
          accuracy: initialPos.accuracy,
          speed: initialPos.speed,
          bearing: initialPos.heading,
          altitude: initialPos.altitude,
          batteryLevel: 100,
          timestamp: now,
          isSynced: false,
        );

        await saveLocationRecord(initialLocEntity);
        logger.i('Initial location point captured & saved on check-in.');
      }
    } catch (e) {
      logger.w('Initial location capture on check-in error: $e');
    }

    return model;
  }

  @override
  Future<AttendanceEntity?> checkOut({required String attendanceId}) async {
    final current = await localDataSource.getAttendanceById(attendanceId);
    if (current == null) return null;

    final updatedModel = AttendanceModel(
      attendanceId: current.attendanceId,
      employeeId: current.employeeId,
      checkInTime: current.checkInTime,
      checkOutTime: DateTime.now(),
      status: 'checked_out',
      isTracking: false,
      createdAt: current.createdAt,
    );

    // Update local database first
    await localDataSource.saveAttendance(updatedModel);
    logger.i('Attendance checked-out saved locally: $attendanceId');

    // Try sync with Remote/Firebase if network is available
    final connectivityResult = await connectivity.checkConnectivity();
    if (_hasNetworkConnection(connectivityResult)) {
      try {
        await remoteDataSource.syncAttendance(updatedModel);
        logger.i('Attendance check-out synced to Firebase immediately.');
      } catch (e) {
        logger.w('Failed immediate sync of check-out, queued for later auto-sync: $e');
      }
    }

    return updatedModel;
  }

  @override
  Future<AttendanceEntity?> getActiveAttendance() async {
    return await localDataSource.getActiveAttendance();
  }

  @override
  Future<void> saveLocationRecord(LocationEntity location) async {
    final model = LocationModel.fromEntity(location);

    final connectivityResult = await connectivity.checkConnectivity();
    final isOnline = _hasNetworkConnection(connectivityResult);

    if (isOnline) {
      try {
        final syncedModel = LocationModel(
          id: model.id,
          attendanceId: model.attendanceId,
          latitude: model.latitude,
          longitude: model.longitude,
          accuracy: model.accuracy,
          speed: model.speed,
          bearing: model.bearing,
          altitude: model.altitude,
          batteryLevel: model.batteryLevel,
          timestamp: model.timestamp,
          isSynced: true,
        );
        await remoteDataSource.syncLocations([syncedModel]);
        await localDataSource.saveLocation(syncedModel);
        logger.i('Location record saved & uploaded to Firebase directly.');
        return;
      } catch (e) {
        logger.w('Direct Firebase upload error (saved locally for background auto-sync): $e');
      }
    }

    await localDataSource.saveLocation(model);
  }

  @override
  Future<LocationEntity?> getLatestLocation() async {
    return await localDataSource.getLatestLocation();
  }

  @override
  Future<int> getUnsyncedLocationsCount() async {
    return await localDataSource.getUnsyncedCount();
  }

  @override
  Future<void> syncPendingData() async {
    final connectivityResult = await connectivity.checkConnectivity();
    if (!_hasNetworkConnection(connectivityResult)) {
      logger.i('Auto-sync skipped: No internet connection.');
      return;
    }

    final unsyncedLocations = await localDataSource.getUnsyncedLocations();
    if (unsyncedLocations.isEmpty) {
      logger.i('Auto-sync: No pending location records found.');
      return;
    }

    try {
      logger.i('Uploading ${unsyncedLocations.length} pending location records to Firebase...');
      await remoteDataSource.syncLocations(unsyncedLocations);

      final idsToMark = unsyncedLocations.map((loc) => loc.id!).whereType<int>().toList();
      await localDataSource.markLocationsAsSynced(idsToMark);
      logger.i('Successfully auto-synced ${idsToMark.length} pending locations to Firebase.');
    } catch (e) {
      logger.e('Auto-sync failed: $e');
    }
  }

  bool _hasNetworkConnection(List<ConnectivityResult> results) {
    return results.any((res) =>
        res == ConnectivityResult.mobile ||
        res == ConnectivityResult.wifi ||
        res == ConnectivityResult.ethernet);
  }
}
