import 'package:equatable/equatable.dart';

class EmployeeEntity extends Equatable {
  final String uid;
  final String email;
  final String name;
  final String role; // 'company' or 'employee'
  final String? companyId;
  final String? companyName;
  final bool isApproved; // For company approval status
  final bool isFirstLogin;

  const EmployeeEntity({
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
}
