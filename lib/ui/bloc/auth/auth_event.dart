import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class CheckAuthStatusEvent extends AuthEvent {}

class LoginSubmittedEvent extends AuthEvent {
  final String email;
  final String password;
  final String role; // 'company' or 'employee'

  const LoginSubmittedEvent({
    required this.email,
    required this.password,
    required this.role,
  });

  @override
  List<Object?> get props => [email, password, role];
}

class CompanyRegisterSubmittedEvent extends AuthEvent {
  final String companyName;
  final String address;
  final String gstNumber;
  final String ownerName;
  final String email;
  final String phone;
  final String password;

  const CompanyRegisterSubmittedEvent({
    required this.companyName,
    required this.address,
    required this.gstNumber,
    required this.ownerName,
    required this.email,
    required this.phone,
    required this.password,
  });

  @override
  List<Object?> get props => [
        companyName,
        address,
        gstNumber,
        ownerName,
        email,
        phone,
        password,
      ];
}

class EmployeeRegisterSubmittedEvent extends AuthEvent {
  final String email;
  final String password;
  final String name;
  final String? companyId;
  final String? companyName;

  const EmployeeRegisterSubmittedEvent({
    required this.email,
    required this.password,
    required this.name,
    this.companyId,
    this.companyName,
  });

  @override
  List<Object?> get props => [email, password, name, companyId, companyName];
}

class ToggleCompanyApprovalDevEvent extends AuthEvent {
  final String companyId;
  final bool isApproved;

  const ToggleCompanyApprovalDevEvent({
    required this.companyId,
    required this.isApproved,
  });

  @override
  List<Object?> get props => [companyId, isApproved];
}

class LogoutSubmittedEvent extends AuthEvent {}
