import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'di/injection_container.dart';
import 'local/services/background_location_service.dart';
import 'local/services/sync_service.dart';
import 'backend/models/employee_model.dart';
import 'backend/repositories/attendance_repository.dart';
import 'ui/bloc/attendance/attendance_bloc.dart';
import 'ui/bloc/attendance/attendance_event.dart';
import 'ui/bloc/auth/auth_bloc.dart';
import 'ui/bloc/auth/auth_event.dart';
import 'ui/bloc/auth/auth_state.dart';
import 'ui/theme/app_theme.dart';
import 'ui/screens/company/company_dashboard_screen.dart';
import 'ui/screens/company/company_pending_screen.dart';
import 'ui/screens/employee/employee_dashboard.dart';
import 'ui/screens/employee/first_login_setup_screen.dart';
import 'ui/screens/employee/quick_login_screen.dart';
import 'ui/screens/role_selection_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization warning: $e');
  }

  // Initialize background location service
  await BackgroundLocationService.initializeService();

  // Initialize Dependency Injection Container
  await initInjection();

  runApp(const AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => sl<AuthBloc>()..add(CheckAuthStatusEvent()),
        ),
        BlocProvider<AttendanceBloc>(
          create: (context) => AttendanceBloc(
            repository: sl<AttendanceRepository>(),
            syncService: SyncService(
              repository: sl<AttendanceRepository>(),
              connectivity: sl(),
            ),
            connectivity: sl(),
          )..add(InitializeAttendance()),
        ),
      ],
      child: MaterialApp(
        title: 'HRMS Attendance System',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthenticatedState) {
              context.read<AttendanceBloc>().add(
                    InitializeAttendance(employeeId: state.user.email),
                  );
            } else if (state is UnauthenticatedState) {
              isQuickLoginUnlockedThisSession = false;
              context.read<AttendanceBloc>().add(
                    const InitializeAttendance(employeeId: null),
                  );
            }
          },
          builder: (context, state) {
            if (state is AuthLoadingState) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (state is CompanyPendingApprovalState) {
              return CompanyPendingScreen(user: state.user);
            }

            if (state is AuthenticatedState) {
              return _AuthenticatedUserGateway(user: state.user);
            }

            return const RoleSelectionScreen();
          },
        ),
      ),
    );
  }
}

class _AuthenticatedUserGateway extends StatefulWidget {
  final EmployeeEntity user;

  const _AuthenticatedUserGateway({required this.user});

  @override
  State<_AuthenticatedUserGateway> createState() => _AuthenticatedUserGatewayState();
}

class _AuthenticatedUserGatewayState extends State<_AuthenticatedUserGateway> {
  late Future<bool> _quickLoginEnabledFuture;

  @override
  void initState() {
    super.initState();
    _quickLoginEnabledFuture = _checkQuickLogin();
  }

  @override
  void didUpdateWidget(covariant _AuthenticatedUserGateway oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.uid != widget.user.uid) {
      _quickLoginEnabledFuture = _checkQuickLogin();
    }
  }

  Future<bool> _checkQuickLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('quick_login_enabled_${widget.user.uid}') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.user.isFirstLogin) {
      return FirstLoginSetupScreen(user: widget.user);
    }

    if (isQuickLoginUnlockedThisSession) {
      if (widget.user.isCompany) {
        return CompanyDashboardScreen(user: widget.user);
      }
      return EmployeeDashboardScreen(user: widget.user);
    }

    return FutureBuilder<bool>(
      future: _quickLoginEnabledFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          if (widget.user.isCompany) {
            return CompanyDashboardScreen(user: widget.user);
          }
          return EmployeeDashboardScreen(user: widget.user);
        }

        if (snapshot.data == true) {
          return QuickLoginScreen(user: widget.user);
        }

        if (widget.user.isCompany) {
          return CompanyDashboardScreen(user: widget.user);
        }

        return EmployeeDashboardScreen(user: widget.user);
      },
    );
  }
}
