import 'package:equatable/equatable.dart';
import '../../domain/entities/employee_entity.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitialState extends AuthState {}

class AuthLoadingState extends AuthState {}

class AuthenticatedState extends AuthState {
  final EmployeeEntity user;

  const AuthenticatedState({required this.user});

  @override
  List<Object?> get props => [user];
}

class CompanyPendingApprovalState extends AuthState {
  final EmployeeEntity user;

  const CompanyPendingApprovalState({required this.user});

  @override
  List<Object?> get props => [user];
}

class UnauthenticatedState extends AuthState {
  final String? errorMessage;

  const UnauthenticatedState({this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];
}
