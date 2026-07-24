import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final fb.FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;
  final SharedPreferences sharedPreferences;
  final Logger logger = Logger();

  static const String keyUserUid = 'cached_user_uid';
  static const String keyUserEmail = 'cached_user_email';
  static const String keyUserName = 'cached_user_name';

  AuthRepositoryImpl({
    required this.firebaseAuth,
    required this.firestore,
    required this.sharedPreferences,
  });

  @override
  Future<UserEntity?> login({required String email, required String password}) async {
    try {
      final userCredential = await firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final fbUser = userCredential.user;
      if (fbUser == null) return null;

      final userModel = UserModel.fromFirebaseUser(fbUser);

      // Save user doc in Firestore 'employees' collection
      try {
        await firestore
            .collection('employees')
            .doc(fbUser.uid)
            .set(userModel.toFirestore(), SetOptions(merge: true));
      } catch (e) {
        logger.w('Firestore employee doc write error: $e');
      }

      // Cache locally for offline persistence
      await _cacheUser(userModel);

      return userModel;
    } on fb.FirebaseAuthException catch (e) {
      logger.e('Firebase Auth Login Error: ${e.message}');
      throw e.message ?? 'Authentication failed.';
    } catch (e) {
      logger.e('Login Error: $e');
      throw 'An unexpected error occurred during login.';
    }
  }

  @override
  Future<UserEntity?> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final userCredential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final fbUser = userCredential.user;
      if (fbUser == null) return null;

      await fbUser.updateDisplayName(name.trim());

      final userModel = UserModel(
        uid: fbUser.uid,
        email: fbUser.email ?? email,
        name: name.trim().isNotEmpty ? name.trim() : email.split('@').first,
      );

      // Save employee document in Firestore
      try {
        await firestore
            .collection('employees')
            .doc(fbUser.uid)
            .set(userModel.toFirestore(), SetOptions(merge: true));
      } catch (e) {
        logger.w('Firestore employee doc write error during registration: $e');
      }

      await _cacheUser(userModel);

      return userModel;
    } on fb.FirebaseAuthException catch (e) {
      logger.e('Firebase Auth Register Error: ${e.message}');
      throw e.message ?? 'Registration failed.';
    } catch (e) {
      logger.e('Registration Error: $e');
      throw 'An unexpected error occurred during registration.';
    }
  }

  @override
  Future<void> logout() async {
    try {
      await firebaseAuth.signOut();
    } catch (e) {
      logger.w('Firebase SignOut error: $e');
    }
    await _clearCachedUser();
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final fbUser = firebaseAuth.currentUser;
    if (fbUser != null) {
      final userModel = UserModel.fromFirebaseUser(fbUser);
      await _cacheUser(userModel);
      return userModel;
    }

    // Fallback to cached user if offline
    final uid = sharedPreferences.getString(keyUserUid);
    final email = sharedPreferences.getString(keyUserEmail);
    final name = sharedPreferences.getString(keyUserName);

    if (uid != null && email != null) {
      return UserEntity(
        uid: uid,
        email: email,
        name: name ?? email.split('@').first,
      );
    }

    return null;
  }

  @override
  Stream<UserEntity?> get authStateChanges {
    return firebaseAuth.authStateChanges().map((fbUser) {
      if (fbUser == null) return null;
      return UserModel.fromFirebaseUser(fbUser);
    });
  }

  Future<void> _cacheUser(UserModel user) async {
    await sharedPreferences.setString(keyUserUid, user.uid);
    await sharedPreferences.setString(keyUserEmail, user.email);
    await sharedPreferences.setString(keyUserName, user.name);
  }

  Future<void> _clearCachedUser() async {
    await sharedPreferences.remove(keyUserUid);
    await sharedPreferences.remove(keyUserEmail);
    await sharedPreferences.remove(keyUserName);
  }
}
