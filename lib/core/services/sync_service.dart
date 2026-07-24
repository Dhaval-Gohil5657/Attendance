import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';

import '../../domain/repositories/attendance_repository.dart';

class SyncService {
  final AttendanceRepository repository;
  final Connectivity connectivity;
  final Logger logger = Logger();

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  SyncService({
    required this.repository,
    required this.connectivity,
  });

  void startListening() {
    _subscription?.cancel();
    _subscription = connectivity.onConnectivityChanged.listen((results) async {
      final isOnline = results.any((res) =>
          res == ConnectivityResult.mobile ||
          res == ConnectivityResult.wifi ||
          res == ConnectivityResult.ethernet);

      if (isOnline) {
        logger.i('Network status changed to ONLINE. Starting auto-synchronization...');
        await repository.syncPendingData();
      } else {
        logger.i('Network status changed to OFFLINE. Operations switched to local storage.');
      }
    });
  }

  Future<void> syncNow() async {
    logger.i('Manual sync triggered.');
    await repository.syncPendingData();
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }
}
