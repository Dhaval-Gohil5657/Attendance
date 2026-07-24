import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';

import '../../data/datasource/local/database/app_database.dart';
import '../../data/datasource/local/local_data_source.dart';
import '../../data/models/location_model.dart';
import '../../domain/entities/location_entity.dart';

@pragma('vm:entry-point')
class BackgroundLocationService {
  static const String notificationChannelId = 'attendance_tracking_channel';
  static const int notificationId = 888;
  static Position? _lastSavedPosition;

  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    // Create Notification Channel for Android 8.0+
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      notificationChannelId,
      'Attendance Live Tracking',
      description: 'Used for continuous employee location tracking.',
      importance: Importance.low,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: notificationChannelId,
        initialNotificationTitle: 'Attendance Tracking Active',
        initialNotificationContent: 'Collecting live location updates...',
        foregroundServiceNotificationId: notificationId,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  static Future<bool> onIosBackground(ServiceInstance service) async {
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    final logger = Logger();
    logger.i('Background Location Service Started.');

    String? activeAttendanceId;
    String? activeEmployeeId;

    service.on('setAttendanceData').listen((event) {
      if (event != null && event['attendanceId'] != null) {
        activeAttendanceId = event['attendanceId'] as String;
        activeEmployeeId = event['employeeId'] as String?;
        logger.i('Background Service received in-memory session: $activeAttendanceId');
      }
    });

    try {
      await Firebase.initializeApp();
      logger.i('Firebase Initialized in Background Isolate.');
    } catch (e) {
      logger.w('Firebase background init error: $e');
    }

    try {
      final database = AppDatabase();
      final localDataSource = LocalDataSourceImpl(database: database);

      if (service is AndroidServiceInstance) {
        service.on('setAsForeground').listen((event) {
          service.setAsForegroundService();
        });

        service.on('setAsBackground').listen((event) {
          service.setAsBackgroundService();
        });
      }

      service.on('stopService').listen((event) {
        activeAttendanceId = null;
        activeEmployeeId = null;
        service.stopSelf();
        logger.i('Background Location Service Stopped.');
      });

      Future<void> fetchAndSaveLocation() async {
        try {
          String? currentAttendanceId = activeAttendanceId;
          String? currentEmployeeId = activeEmployeeId;

          // If in-memory is null, fallback to local database query
          if (currentAttendanceId == null) {
            final activeAttendance = await localDataSource.getActiveAttendance();
            if (activeAttendance != null && activeAttendance.isTracking) {
              currentAttendanceId = activeAttendance.attendanceId;
              currentEmployeeId = activeAttendance.employeeId;
              activeAttendanceId = currentAttendanceId;
              activeEmployeeId = currentEmployeeId;
            }
          }

          if (currentAttendanceId == null) {
            logger.i('No active tracking session found in memory or database.');
            return;
          }

          // Request fresh live GPS location from Android hardware manager
          Position? position;
          try {
            position = await Geolocator.getCurrentPosition(
              locationSettings: AndroidSettings(
                accuracy: LocationAccuracy.high,
                distanceFilter: 0,
                forceLocationManager: true,
                timeLimit: const Duration(seconds: 10),
              ),
            );
          } catch (e) {
            logger.w('getCurrentPosition fallback to getLastKnownPosition: $e');
            position = await Geolocator.getLastKnownPosition();
          }

          if (position == null) {
            logger.w('No position available.');
            return;
          }

          // Accuracy Filter: Ignore weak signal / cell tower jumps (> 15 meters accuracy)
          if (position.accuracy > 15.0) {
            logger.i('Accuracy filter: signal accuracy ${position.accuracy.toStringAsFixed(1)}m is > 15.0m (weak GPS signal / cell tower jump). Skipping.');
            return;
          }

          // Stationary & Walking Filter: Require 8.0 meters movement (approx 10 walking steps) to filter all stationary indoor noise
          if (_lastSavedPosition != null) {
            final distanceMoved = Geolocator.distanceBetween(
              _lastSavedPosition!.latitude,
              _lastSavedPosition!.longitude,
              position.latitude,
              position.longitude,
            );
            if (distanceMoved < 8.0) {
              logger.i('Stationary filter: distance ${distanceMoved.toStringAsFixed(2)}m is < 8.0m (stationary desk noise). Skipping upload.');
              return;
            }
            logger.i('✅ WALKING VERIFIED: Moved ${distanceMoved.toStringAsFixed(2)}m >= 8.0m. Pushing 1 location log to Firestore...');
          } else {
            logger.i('✅ INITIAL POSITION CAPTURED: Pushing initial location log to Firestore...');
          }
          _lastSavedPosition = position;

          bool isSynced = false;

          // Attempt real-time upload to Firestore location_logs collection
          try {
            final locData = {
              'attendanceId': currentAttendanceId,
              'employeeId': currentEmployeeId ?? 'EMP_DUMMY_001',
              'latitude': position.latitude,
              'longitude': position.longitude,
              'accuracy': position.accuracy,
              'speed': position.speed,
              'bearing': position.heading,
              'altitude': position.altitude,
              'batteryLevel': 100,
              'timestamp': Timestamp.fromDate(DateTime.now()),
            };

            await FirebaseFirestore.instance.collection('location_logs').add(locData);
            isSynced = true;
            logger.i('🚀 Successfully synced 1 location log to Firestore (Lat: ${position.latitude.toStringAsFixed(5)}, Lng: ${position.longitude.toStringAsFixed(5)}).');
          } catch (e) {
            logger.w('Firestore live upload error (queued for auto-sync): $e');
          }

          final locationEntity = LocationEntity(
            attendanceId: currentAttendanceId,
            latitude: position.latitude,
            longitude: position.longitude,
            accuracy: position.accuracy,
            speed: position.speed,
            bearing: position.heading,
            altitude: position.altitude,
            batteryLevel: 100,
            timestamp: DateTime.now(),
            isSynced: isSynced,
          );

          final model = LocationModel.fromEntity(locationEntity);
          await localDataSource.saveLocation(model);
          logger.i('Background Service: Saved location (${position.latitude}, ${position.longitude}) to local DB.');

          if (service is AndroidServiceInstance) {
            service.setForegroundNotificationInfo(
              title: 'Tracking Active (${currentAttendanceId.substring(0, 8)})',
              content: 'Lat: ${position.latitude.toStringAsFixed(5)}, Long: ${position.longitude.toStringAsFixed(5)}',
            );
          }

          // Notify UI of live location update
          service.invoke('updateLocation', {
            'latitude': position.latitude,
            'longitude': position.longitude,
            'timestamp': DateTime.now().toIso8601String(),
          });
        } catch (e) {
          logger.e('Background Service Location Fetch Error: $e');
        }
      }

      // Immediate initial fetch
      fetchAndSaveLocation();

      // Run periodic location tracking every 5 seconds
      Timer.periodic(const Duration(seconds: 5), (timer) async {
        try {
          if (activeAttendanceId == null) {
            final activeAttendance = await localDataSource.getActiveAttendance();
            if (activeAttendance == null || !activeAttendance.isTracking) {
              logger.i('Stopping background location timer.');
              timer.cancel();
              service.stopSelf();
              return;
            }
          }
          fetchAndSaveLocation();
        } catch (e) {
          logger.e('Timer periodic error: $e');
        }
      });
    } catch (e) {
      logger.e('Background Service Fatal Error: $e');
    }
  }

  static Future<void> startTracking({
    String? attendanceId,
    String? employeeId,
  }) async {
    _lastSavedPosition = null;
    try {
      final service = FlutterBackgroundService();
      final isRunning = await service.isRunning();
      if (!isRunning) {
        await service.startService();
      }
      if (attendanceId != null) {
        service.invoke('setAttendanceData', {
          'attendanceId': attendanceId,
          'employeeId': employeeId,
        });
      }
    } catch (e) {
      debugPrint('Error starting background service: $e');
    }
  }

  static Future<void> stopTracking() async {
    try {
      final service = FlutterBackgroundService();
      final isRunning = await service.isRunning();
      if (isRunning) {
        service.invoke('stopService');
      }
    } catch (e) {
      debugPrint('Error stopping background service: $e');
    }
  }
}
