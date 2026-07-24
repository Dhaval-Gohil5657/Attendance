import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthInitialState()) {
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<LoginSubmittedEvent>(_onLoginSubmitted);
    on<RegisterSubmittedEvent>(_onRegisterSubmitted);
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
        emit(AuthenticatedState(user: currentUser));
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
      );

      if (user != null) {
        emit(AuthenticatedState(user: user));
      } else {
        emit(const UnauthenticatedState(errorMessage: 'Invalid login credentials.'));
      }
    } catch (e) {
      emit(UnauthenticatedState(errorMessage: e.toString()));
    }
  }

  Future<void> _onRegisterSubmitted(
    RegisterSubmittedEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoadingState());
    try {
      final user = await authRepository.register(
        email: event.email,
        password: event.password,
        name: event.name,
      );

      if (user != null) {
        emit(AuthenticatedState(user: user));
      } else {
        emit(const UnauthenticatedState(errorMessage: 'Registration failed.'));
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
    await authRepository.logout();
    emit(const UnauthenticatedState());
  }
}
