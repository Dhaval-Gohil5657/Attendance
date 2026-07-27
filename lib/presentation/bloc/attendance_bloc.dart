import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/helpers/permission_helper.dart';
import '../../core/services/background_location_service.dart';
import '../../core/services/sync_service.dart';
import '../../domain/repositories/attendance_repository.dart';
import 'attendance_event.dart';
import 'attendance_state.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final AttendanceRepository repository;
  final SyncService syncService;
  final Connectivity connectivity;
  StreamSubscription? _connectivitySub;
  StreamSubscription? _bgServiceSub;
  StreamSubscription<Position>? _positionStreamSub;

  AttendanceBloc({
    required this.repository,
    required this.syncService,
    required this.connectivity,
  }) : super(const AttendanceState()) {
    on<InitializeAttendance>(_onInitialize);
    on<CheckInEvent>(_onCheckIn);
    on<CheckOutEvent>(_onCheckOut);
    on<SyncNowEvent>(_onSyncNow);
    on<UpdateLocationDataEvent>(_onUpdateLocation);
    on<NetworkStatusChangedEvent>(_onNetworkStatusChanged);

    _listenConnectivity();
    _listenBackgroundService();
  }

  void _listenPositionStream() {
    _positionStreamSub?.cancel();
    _positionStreamSub = Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        forceLocationManager: true,
        intervalDuration: const Duration(seconds: 5),
      ),
    ).listen((position) {
      add(UpdateLocationDataEvent(
        latitude: position.latitude,
        longitude: position.longitude,
      ));
    });
  }

  void _listenConnectivity() {
    _connectivitySub = connectivity.onConnectivityChanged.listen((results) {
      final isOnline = results.any((res) =>
          res == ConnectivityResult.mobile ||
          res == ConnectivityResult.wifi ||
          res == ConnectivityResult.ethernet);
      add(NetworkStatusChangedEvent(isOnline: isOnline));
    });
  }

  void _listenBackgroundService() {
    _bgServiceSub = FlutterBackgroundService().on('updateLocation').listen((event) {
      if (event != null && event['latitude'] != null && event['longitude'] != null) {
        add(UpdateLocationDataEvent(
          latitude: (event['latitude'] as num).toDouble(),
          longitude: (event['longitude'] as num).toDouble(),
        ));
      }
    });
  }

  Future<void> _onInitialize(
    InitializeAttendance event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    // Request permissions sequentially (Foreground -> Background -> Notification -> Battery)
    final hasPermission = await PermissionHelper.requestAllPermissions();

    final active = await repository.getActiveAttendance();
    final latestLoc = await repository.getLatestLocation();
    final count = await repository.getUnsyncedLocationsCount();

    double? lat = latestLoc?.latitude;
    double? lng = latestLoc?.longitude;

    if (hasPermission) {
      _listenPositionStream();
      try {
        final isGpsEnabled = await Geolocator.isLocationServiceEnabled();
        if (isGpsEnabled) {
          Position? pos = await Geolocator.getLastKnownPosition();
          pos ??= await Geolocator.getCurrentPosition(
            locationSettings: AndroidSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 0,
              forceLocationManager: false,
              timeLimit: const Duration(seconds: 10),
            ),
          );
          lat = pos.latitude;
          lng = pos.longitude;
        }
      } catch (_) {}
    }

    if (active != null && active.isTracking) {
      await BackgroundLocationService.startTracking(
        attendanceId: active.attendanceId,
        employeeId: active.employeeId,
      );
    }

    emit(state.copyWith(
      isLoading: false,
      activeAttendance: () => active,
      currentLatitude: () => lat,
      currentLongitude: () => lng,
      unsyncedCount: count,
    ));

    syncService.startListening();
  }

  Future<void> _onCheckIn(
    CheckInEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: () => null));

    try {
      // Ensure permissions are granted
      final hasPermission = await PermissionHelper.requestAllPermissions();
      if (!hasPermission) {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: () => 'Location permission is required to mark attendance.',
        ));
        return;
      }
      _listenPositionStream();
      // Ensure GPS is enabled
      final isGpsEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isGpsEnabled) {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: () => 'Please enable GPS/Location service to check in.',
        ));
        return;
      }

      final newAttendance = await repository.checkIn(
        employeeId: event.employeeId.isEmpty ? 'EMP_DUMMY_001' : event.employeeId,
      );

      double? lat = state.currentLatitude;
      double? lng = state.currentLongitude;

      try {
        Position? pos = await Geolocator.getLastKnownPosition();
        pos ??= await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 3),
          ),
        );
        if (pos != null) {
          lat = pos.latitude;
          lng = pos.longitude;
        }
      } catch (_) {}

      // Start continuous background location service with instant initial position
      await BackgroundLocationService.startTracking(
        attendanceId: newAttendance.attendanceId,
        employeeId: newAttendance.employeeId,
        lat: lat,
        lng: lng,
      );

      final count = await repository.getUnsyncedLocationsCount();

      emit(state.copyWith(
        isLoading: false,
        activeAttendance: () => newAttendance,
        currentLatitude: () => lat,
        currentLongitude: () => lng,
        unsyncedCount: count,
        successMessage: () => 'Attendance Marked! Background tracking active.',
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: () => 'Failed to mark attendance: $e',
      ));
    }
  }

  Future<void> _onCheckOut(
    CheckOutEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    if (state.activeAttendance == null) return;

    emit(state.copyWith(isLoading: true, errorMessage: () => null));

    try {
      await repository.checkOut(attendanceId: state.activeAttendance!.attendanceId);
      await BackgroundLocationService.stopTracking();

      final count = await repository.getUnsyncedLocationsCount();

      emit(state.copyWith(
        isLoading: false,
        activeAttendance: () => null,
        unsyncedCount: count,
        successMessage: () => 'Checked Out successfully. Location tracking stopped.',
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: () => 'Failed to check out: $e',
      ));
    }
  }

  Future<void> _onSyncNow(
    SyncNowEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    await syncService.syncNow();
    final count = await repository.getUnsyncedLocationsCount();
    emit(state.copyWith(
      isLoading: false,
      unsyncedCount: count,
      successMessage: event.isManualSync ? () => 'Sync completed!' : () => null,
    ));
  }

  Future<void> _onUpdateLocation(
    UpdateLocationDataEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    final count = await repository.getUnsyncedLocationsCount();
    emit(state.copyWith(
      currentLatitude: () => event.latitude,
      currentLongitude: () => event.longitude,
      unsyncedCount: count,
      successMessage: () => null,
    ));
  }

  Future<void> _onNetworkStatusChanged(
    NetworkStatusChangedEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(state.copyWith(isOnline: event.isOnline));
    if (event.isOnline) {
      add(const SyncNowEvent(isManualSync: false));
    }
  }

  @override
  Future<void> close() {
    _connectivitySub?.cancel();
    _bgServiceSub?.cancel();
    _positionStreamSub?.cancel();
    return super.close();
  }
}
