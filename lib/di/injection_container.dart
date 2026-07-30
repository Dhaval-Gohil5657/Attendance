import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../local/database/app_database.dart';
import '../local/datasource/local_data_source.dart';
import '../backend/services/firebase_remote_data_source.dart';
import '../backend/services/remote_data_source.dart';
import '../backend/repositories/attendance_repository_impl.dart';
import '../backend/repositories/auth_repository_impl.dart';
import '../backend/repositories/attendance_repository.dart';
import '../backend/repositories/auth_repository.dart';
import '../ui/bloc/auth/auth_bloc.dart';

final sl = GetIt.instance;

Future<void> initInjection() async {
  // External & Preferences
  final prefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => prefs);
  sl.registerLazySingleton<Connectivity>(() => Connectivity());
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);

  // Database
  sl.registerLazySingleton<AppDatabase>(() => AppDatabase());

  // Data Sources
  sl.registerLazySingleton<LocalDataSource>(
    () => LocalDataSourceImpl(database: sl<AppDatabase>()),
  );
  sl.registerLazySingleton<RemoteDataSource>(
    () => FirebaseRemoteDataSourceImpl(
      firestore: sl<FirebaseFirestore>(),
      firebaseAuth: sl<FirebaseAuth>(),
    ),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      firebaseAuth: sl<FirebaseAuth>(),
      firestore: sl<FirebaseFirestore>(),
      sharedPreferences: sl<SharedPreferences>(),
    ),
  );
  sl.registerLazySingleton<AttendanceRepository>(
    () => AttendanceRepositoryImpl(
      localDataSource: sl<LocalDataSource>(),
      remoteDataSource: sl<RemoteDataSource>(),
      connectivity: sl<Connectivity>(),
    ),
  );

  // Blocs
  sl.registerFactory<AuthBloc>(
    () => AuthBloc(authRepository: sl<AuthRepository>()),
  );
}
