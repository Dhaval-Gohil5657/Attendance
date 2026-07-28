import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../domain/entities/employee_entity.dart';

class EmployeeModel extends EmployeeEntity {
  const EmployeeModel({
    required super.uid,
    required super.email,
    required super.name,
    super.role = 'employee',
    super.companyId,
    super.companyName,
    super.isApproved = true,
    super.isFirstLogin = false,
  });

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
