import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection_container.dart';
import 'core/services/background_location_service.dart';
import 'core/services/sync_service.dart';
import 'domain/repositories/attendance_repository.dart';
import 'presentation/bloc/attendance_bloc.dart';
import 'presentation/bloc/attendance_event.dart';
import 'presentation/bloc/auth_bloc.dart';
import 'presentation/bloc/auth_event.dart';
import 'presentation/bloc/auth_state.dart';
import 'presentation/screens/company/company_dashboard_screen.dart';
import 'presentation/screens/company/company_pending_screen.dart';
import 'presentation/screens/employee/first_login_setup_screen.dart';
import 'presentation/screens/employee/employee_dashboard.dart';
import 'presentation/screens/role_selection_screen.dart';

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
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.indigo,
            brightness: Brightness.light,
          ),
        ),
        home: BlocBuilder<AuthBloc, AuthState>(
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
              if (state.user.isCompany) {
                return CompanyDashboardScreen(user: state.user);
              }
              if (state.user.isFirstLogin) {
                return FirstLoginSetupScreen(user: state.user);
              }
              return EmployeeDashboardScreen(user: state.user);
            }

            return const RoleSelectionScreen();
          },
        ),
      ),
    );
  }
}
