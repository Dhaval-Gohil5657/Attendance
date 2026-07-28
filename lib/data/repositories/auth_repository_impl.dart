import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/company_entity.dart';
import '../../domain/entities/employee_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/company_model.dart';
import '../models/employee_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final fb.FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;
  final SharedPreferences sharedPreferences;
  final Logger logger = Logger();

  static const String keyUserUid = 'cached_user_uid';
  static const String keyUserEmail = 'cached_user_email';
  static const String keyUserName = 'cached_user_name';
  static const String keyUserRole = 'cached_user_role';
  static const String keyCompanyId = 'cached_company_id';
  static const String keyCompanyName = 'cached_company_name';
  static const String keyIsApproved = 'cached_is_approved';
  static const String keyIsFirstLogin = 'cached_is_first_login';

  AuthRepositoryImpl({
    required this.firebaseAuth,
    required this.firestore,
    required this.sharedPreferences,
  });

  @override
  Future<EmployeeEntity?> login({
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final userCredential = await firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final fbUser = userCredential.user;
      if (fbUser == null) return null;

      bool isApproved = true;
      String? companyId;
      String? companyName;
      String name = fbUser.displayName ?? email.split('@').first;
      bool isFirstLogin = false;

      if (role == 'company') {
        try {
          final compDoc = await firestore.collection('companies').doc(fbUser.uid).get();
          if (compDoc.exists && compDoc.data() != null) {
            final data = compDoc.data()!;
            companyName = data['companyName'];
            name = data['ownerName'] ?? companyName ?? name;
            isApproved = data['isApproved'] ?? false;
            companyId = fbUser.uid;
          } else {
            isApproved = false; // default pending if doc missing
          }
        } catch (e) {
          logger.w('Error reading Firestore company doc: $e');
          isApproved = false;
        }
      } else {
        // Employee role
        try {
          final empDoc = await firestore.collection('employees').doc(fbUser.uid).get();
          if (empDoc.exists && empDoc.data() != null) {
            final data = empDoc.data()!;
            name = data['name'] ?? name;
            companyId = data['companyId'];
            companyName = data['companyName'];
            isFirstLogin = data['isFirstLogin'] ?? false;
          }
        } catch (e) {
          logger.w('Error reading Firestore employee doc: $e');
        }
      }

      final employeeModel = EmployeeModel(
        uid: fbUser.uid,
        email: fbUser.email ?? email,
        name: name,
        role: role,
        companyId: companyId ?? (role == 'company' ? fbUser.uid : null),
        companyName: companyName,
        isApproved: isApproved,
        isFirstLogin: isFirstLogin,
      );

      await _cacheUser(employeeModel);
      return employeeModel;
    } on fb.FirebaseAuthException catch (e) {
      logger.e('Firebase Auth Login Error: ${e.message}');
      throw e.message ?? 'Authentication failed.';
    } catch (e) {
      logger.e('Login Error: $e');
      throw 'An unexpected error occurred during login.';
    }
  }

  @override
  Future<CompanyEntity?> registerCompany({
    required String companyName,
    required String address,
    required String gstNumber,
    required String ownerName,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final userCredential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final fbUser = userCredential.user;
      if (fbUser == null) return null;

      await fbUser.updateDisplayName(ownerName.trim());

      final companyModel = CompanyModel(
        companyId: fbUser.uid,
        companyName: companyName.trim(),
        address: address.trim(),
        gstNumber: gstNumber.trim(),
        ownerName: ownerName.trim(),
        email: email.trim(),
        phone: phone.trim(),
        isApproved: false, // Default pending admin approval
        createdAt: DateTime.now(),
      );

      final employeeModel = EmployeeModel(
        uid: fbUser.uid,
        email: email.trim(),
        name: ownerName.trim(),
        role: 'company',
        companyId: fbUser.uid,
        companyName: companyName.trim(),
        isApproved: false,
        isFirstLogin: false,
      );

      try {
        await firestore
            .collection('companies')
            .doc(fbUser.uid)
            .set(companyModel.toFirestore(), SetOptions(merge: true));
      } catch (e) {
        logger.w('Firestore company doc write error: $e');
      }

      await _cacheUser(employeeModel);
      return companyModel;
    } on fb.FirebaseAuthException catch (e) {
      logger.e('Firebase Auth Register Company Error: ${e.message}');
      throw e.message ?? 'Company registration failed.';
    } catch (e) {
      logger.e('Company Registration Error: $e');
      throw 'An unexpected error occurred during company registration.';
    }
  }

  @override
  Future<EmployeeEntity?> registerEmployee({
    required String email,
    required String password,
    required String name,
    String? companyId,
    String? companyName,
  }) async {
    try {
      fb.FirebaseAuth targetAuth = firebaseAuth;
      FirebaseApp? secondaryApp;

      // If a company user is logged in, use a secondary FirebaseApp instance
      // so registering an employee does NOT sign out or switch the company session!
      if (firebaseAuth.currentUser != null) {
        try {
          final appName = 'empApp_${DateTime.now().millisecondsSinceEpoch}';
          secondaryApp = await Firebase.initializeApp(
            name: appName,
            options: Firebase.app().options,
          );
          targetAuth = fb.FirebaseAuth.instanceFor(app: secondaryApp);
        } catch (e) {
          logger.w('Secondary FirebaseApp init warning: $e');
        }
      }

      final userCredential = await targetAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final fbUser = userCredential.user;
      if (fbUser == null) return null;

      await fbUser.updateDisplayName(name.trim());

      final employeeModel = EmployeeModel(
        uid: fbUser.uid,
        email: fbUser.email ?? email,
        name: name.trim(),
        role: 'employee',
        companyId: companyId,
        companyName: companyName,
        isApproved: true,
        isFirstLogin: true,
      );

      try {
        await firestore
            .collection('employees')
            .doc(fbUser.uid)
            .set(employeeModel.toFirestore(), SetOptions(merge: true));
      } catch (e) {
        logger.w('Firestore employee doc write error: $e');
      }

      if (secondaryApp != null) {
        await targetAuth.signOut();
        await secondaryApp.delete();
      } else {
        await _cacheUser(employeeModel);
      }

      return employeeModel;
    } on fb.FirebaseAuthException catch (e) {
      logger.e('Firebase Auth Register Employee Error: ${e.message}');
      throw e.message ?? 'Employee registration failed.';
    } catch (e) {
      logger.e('Employee Registration Error: $e');
      throw 'An unexpected error occurred during employee registration.';
    }
  }

  @override
  Future<void> updateCompanyApprovalStatus({
    required String companyId,
    required bool isApproved,
  }) async {
    try {
      await firestore.collection('companies').doc(companyId).update({'isApproved': isApproved});

      if (sharedPreferences.getString(keyUserUid) == companyId) {
        await sharedPreferences.setBool(keyIsApproved, isApproved);
      }
    } catch (e) {
      logger.e('Update approval status error: $e');
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
  Future<EmployeeEntity?> getCurrentUser() async {
    final fbUser = firebaseAuth.currentUser;
    if (fbUser != null) {
      final uid = fbUser.uid;
      final role = sharedPreferences.getString(keyUserRole) ?? 'employee';
      final companyId = sharedPreferences.getString(keyCompanyId);
      final companyName = sharedPreferences.getString(keyCompanyName);
      final isApproved = sharedPreferences.getBool(keyIsApproved) ?? (role == 'employee');
      final isFirstLogin = sharedPreferences.getBool(keyIsFirstLogin) ?? false;
      final name = fbUser.displayName ?? fbUser.email?.split('@').first ?? 'User';

      return EmployeeModel(
        uid: uid,
        email: fbUser.email ?? '',
        name: name,
        role: role,
        companyId: companyId,
        companyName: companyName,
        isApproved: isApproved,
        isFirstLogin: isFirstLogin,
      );
    }

    final uid = sharedPreferences.getString(keyUserUid);
    final email = sharedPreferences.getString(keyUserEmail);
    final name = sharedPreferences.getString(keyUserName);
    final role = sharedPreferences.getString(keyUserRole);

    if (uid != null && email != null && role != null) {
      return EmployeeEntity(
        uid: uid,
        email: email,
        name: name ?? email.split('@').first,
        role: role,
        companyId: sharedPreferences.getString(keyCompanyId),
        companyName: sharedPreferences.getString(keyCompanyName),
        isApproved: sharedPreferences.getBool(keyIsApproved) ?? (role == 'employee'),
        isFirstLogin: sharedPreferences.getBool(keyIsFirstLogin) ?? false,
      );
    }

    return null;
  }

  @override
  Stream<EmployeeEntity?> get authStateChanges {
    return firebaseAuth.authStateChanges().map((fbUser) {
      if (fbUser == null) return null;
      return EmployeeModel.fromFirebaseUser(fbUser);
    });
  }

  Future<void> _cacheUser(EmployeeModel user) async {
    await sharedPreferences.setString(keyUserUid, user.uid);
    await sharedPreferences.setString(keyUserEmail, user.email);
    await sharedPreferences.setString(keyUserName, user.name);
    await sharedPreferences.setString(keyUserRole, user.role);
    if (user.companyId != null) {
      await sharedPreferences.setString(keyCompanyId, user.companyId!);
    } else {
      await sharedPreferences.remove(keyCompanyId);
    }
    if (user.companyName != null) {
      await sharedPreferences.setString(keyCompanyName, user.companyName!);
    } else {
      await sharedPreferences.remove(keyCompanyName);
    }
    await sharedPreferences.setBool(keyIsApproved, user.isApproved);
    await sharedPreferences.setBool(keyIsFirstLogin, user.isFirstLogin);
  }

  Future<void> _clearCachedUser() async {
    await sharedPreferences.remove(keyUserUid);
    await sharedPreferences.remove(keyUserEmail);
    await sharedPreferences.remove(keyUserName);
    await sharedPreferences.remove(keyUserRole);
    await sharedPreferences.remove(keyCompanyId);
    await sharedPreferences.remove(keyCompanyName);
    await sharedPreferences.remove(keyIsApproved);
    await sharedPreferences.remove(keyIsFirstLogin);
  }
}
