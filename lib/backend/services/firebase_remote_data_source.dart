import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

import '../models/attendance_model.dart';
import '../models/location_model.dart';
import 'remote_data_source.dart';

class FirebaseRemoteDataSourceImpl implements RemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth firebaseAuth;
  final Logger logger = Logger();

  FirebaseRemoteDataSourceImpl({
    required this.firestore,
    required this.firebaseAuth,
  });

  @override
  Future<String?> getCurrentUserId() async {
    try {
      final currentUser = firebaseAuth.currentUser;
      if (currentUser != null) {
        return currentUser.uid;
      }
      // Anonymous auth fallback if user not logged in yet
      final userCreds = await firebaseAuth.signInAnonymously();
      return userCreds.user?.uid;
    } catch (e) {
      logger.e('Firebase RemoteDataSource getCurrentUserId Error: $e');
      return null;
    }
  }

  @override
  Future<void> syncAttendance(AttendanceModel attendance) async {
    try {
      await firestore
          .collection('attendance')
          .doc(attendance.attendanceId)
          .set(attendance.toFirestore(), SetOptions(merge: true));
      logger.i('Successfully synced Attendance ID ${attendance.attendanceId} to Firestore.');
    } catch (e) {
      logger.e('Firebase RemoteDataSource syncAttendance Error: $e');
      rethrow;
    }
  }

  @override
  Future<void> syncLocations(List<LocationModel> locations) async {
    if (locations.isEmpty) return;

    try {
      final batch = firestore.batch();
      for (final loc in locations) {
        final docRef = firestore.collection('location_logs').doc();
        batch.set(docRef, loc.toFirestore());
      }
      await batch.commit();
      logger.i('Successfully batch synced ${locations.length} locations to Firestore.');
    } catch (e) {
      logger.e('Firebase RemoteDataSource syncLocations Error: $e');
      rethrow;
    }
  }
}
