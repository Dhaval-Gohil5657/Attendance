import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

class EmployeeModel extends Equatable {
  final String uid;
  final String email;
  final String name;
  final String role; // 'company' or 'employee'
  final String? companyId;
  final String? companyName;
  final bool isApproved; // For company approval status
  final bool isFirstLogin;

  const EmployeeModel({
    required this.uid,
    required this.email,
    required this.name,
    this.role = 'employee',
    this.companyId,
    this.companyName,
    this.isApproved = true,
    this.isFirstLogin = false,
  });

  bool get isCompany => role == 'company';
  bool get isEmployee => role == 'employee';

  @override
  List<Object?> get props => [
        uid,
        email,
        name,
        role,
        companyId,
        companyName,
        isApproved,
        isFirstLogin,
      ];

  factory EmployeeModel.fromFirebaseUser(
    fb.User user, {
    String role = 'employee',
    String? companyId,
    String? companyName,
    bool isApproved = true,
    bool isFirstLogin = false,
  }) {
    return EmployeeModel(
      uid: user.uid,
      email: user.email ?? '',
      name: user.displayName ?? (user.email != null ? user.email!.split('@').first : 'Employee'),
      role: role,
      companyId: companyId,
      companyName: companyName,
      isApproved: isApproved,
      isFirstLogin: isFirstLogin,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'employeeId': uid,
      'email': email,
      'name': name,
      'role': role,
      'companyId': companyId,
      'companyName': companyName,
      'isApproved': isApproved,
      'isFirstLogin': isFirstLogin,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  factory EmployeeModel.fromMap(Map<String, dynamic> map, String uid) {
    return EmployeeModel(
      uid: uid,
      email: map['email'] ?? '',
      name: map['name'] ?? map['employeeName'] ?? 'Employee',
      role: map['role'] ?? 'employee',
      companyId: map['companyId'],
      companyName: map['companyName'],
      isApproved: map['isApproved'] ?? true,
      isFirstLogin: map['isFirstLogin'] ?? false,
    );
  }
}

typedef EmployeeEntity = EmployeeModel;
