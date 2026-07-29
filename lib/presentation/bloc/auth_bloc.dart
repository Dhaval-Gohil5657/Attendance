import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/auth_repository.dart';
import '../screens/employee/quick_login_screen.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthInitialState()) {
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<LoginSubmittedEvent>(_onLoginSubmitted);
    on<CompanyRegisterSubmittedEvent>(_onCompanyRegisterSubmitted);
    on<EmployeeRegisterSubmittedEvent>(_onEmployeeRegisterSubmitted);
    on<ToggleCompanyApprovalDevEvent>(_onToggleCompanyApprovalDev);
    on<LogoutSubmittedEvent>(_onLogoutSubmitted);
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoadingState());
    try {
      final currentUser = await authRepository.getCurrentUser();
      if (currentUser != null) {
        if (currentUser.isCompany && !currentUser.isApproved) {
          emit(CompanyPendingApprovalState(user: currentUser));
        } else {
          emit(AuthenticatedState(user: currentUser));
        }
      } else {
        emit(const UnauthenticatedState());
      }
    } catch (_) {
      emit(const UnauthenticatedState());
    }
  }

  Future<void> _onLoginSubmitted(
    LoginSubmittedEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoadingState());
    try {
      final user = await authRepository.login(
        email: event.email,
        password: event.password,
        role: event.role,
      );

      if (user != null) {
        if (user.isCompany && !user.isApproved) {
          emit(CompanyPendingApprovalState(user: user));
        } else {
          emit(AuthenticatedState(user: user));
        }
      } else {
        emit(const UnauthenticatedState(errorMessage: 'Invalid login credentials.'));
      }
    } catch (e) {
      emit(UnauthenticatedState(errorMessage: e.toString()));
    }
  }

  Future<void> _onCompanyRegisterSubmitted(
    CompanyRegisterSubmittedEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoadingState());
    try {
      final company = await authRepository.registerCompany(
        companyName: event.companyName,
        address: event.address,
        gstNumber: event.gstNumber,
        ownerName: event.ownerName,
        email: event.email,
        phone: event.phone,
        password: event.password,
      );

      if (company != null) {
        final currentUser = await authRepository.getCurrentUser();
        if (currentUser != null) {
          emit(CompanyPendingApprovalState(user: currentUser));
        } else {
          emit(const UnauthenticatedState(errorMessage: 'Registration succeeded, please log in.'));
        }
      } else {
        emit(const UnauthenticatedState(errorMessage: 'Company registration failed.'));
      }
    } catch (e) {
      emit(UnauthenticatedState(errorMessage: e.toString()));
    }
  }

  Future<void> _onEmployeeRegisterSubmitted(
    EmployeeRegisterSubmittedEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final employee = await authRepository.registerEmployee(
        email: event.email,
        password: event.password,
        name: event.name,
        companyId: event.companyId,
        companyName: event.companyName,
      );

      final currentUser = await authRepository.getCurrentUser();
      if (currentUser != null) {
        if (currentUser.isCompany && !currentUser.isApproved) {
          emit(CompanyPendingApprovalState(user: currentUser));
        } else {
          emit(AuthenticatedState(user: currentUser));
        }
      } else if (employee != null) {
        emit(AuthenticatedState(user: employee));
      } else {
        emit(const UnauthenticatedState(errorMessage: 'Employee registration failed.'));
      }
    } catch (e) {
      final currentUser = await authRepository.getCurrentUser();
      if (currentUser != null) {
        emit(AuthenticatedState(user: currentUser));
      } else {
        emit(UnauthenticatedState(errorMessage: e.toString()));
      }
    }
  }

  Future<void> _onToggleCompanyApprovalDev(
    ToggleCompanyApprovalDevEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoadingState());
    try {
      await authRepository.updateCompanyApprovalStatus(
        companyId: event.companyId,
        isApproved: event.isApproved,
      );
      final currentUser = await authRepository.getCurrentUser();
      if (currentUser != null) {
        if (currentUser.isCompany && !currentUser.isApproved) {
          emit(CompanyPendingApprovalState(user: currentUser));
        } else {
          emit(AuthenticatedState(user: currentUser));
        }
      } else {
        emit(const UnauthenticatedState());
      }
    } catch (e) {
      emit(UnauthenticatedState(errorMessage: e.toString()));
    }
  }

  Future<void> _onLogoutSubmitted(
    LogoutSubmittedEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoadingState());
    isQuickLoginUnlockedThisSession = false;
    await authRepository.logout();
    emit(const UnauthenticatedState());
  }
}
