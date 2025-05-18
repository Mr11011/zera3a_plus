import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import '../feature/auth/auth_cubit.dart';
import '../feature/home/controller/plot_cubit.dart';
import '../feature/irrigation/irrigation_cubit.dart';
import '../feature/workers/workers_cubit.dart';

final GetIt sl = GetIt.instance;

Future<void> init() async {
  // Firebase Auth (singleton)
  sl.registerLazySingleton<FirebaseAuth>(
    () => FirebaseAuth.instance,
  );

  // FirebaseFirestore (singleton)
  sl.registerLazySingleton<FirebaseFirestore>(
    () => FirebaseFirestore.instance,
  );

  // AuthCubit
  sl.registerSingleton<AuthCubit>(
    AuthCubit(
        firebaseAuth: sl<FirebaseAuth>(), firestore: sl<FirebaseFirestore>()),
  );

  // PlotCubit
  sl.registerSingleton<PlotCubit>(
    PlotCubit(
      firebaseAuth: sl<FirebaseAuth>(),
      firestore: sl<FirebaseFirestore>(),
    ),
  );

// IrrigationCubit
  sl.registerFactory<IrrigationCubit>(() => IrrigationCubit(
        firebaseAuth: sl<FirebaseAuth>(),
        firestore: sl<FirebaseFirestore>(),
      ));

  // lib/core/di.dart
  sl.registerFactory<LaborCubit>(() => LaborCubit(
    firebaseAuth: sl<FirebaseAuth>(),
    firestore: sl<FirebaseFirestore>(),
  ));
}
