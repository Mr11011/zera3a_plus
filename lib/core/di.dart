import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import '../feature/auth/auth_cubit.dart';
import '../feature/home/controller/plot_cubit.dart';
import '../feature/inventory/controller/inventory_cubit.dart';
import '../feature/irrigation/irrigation_cubit.dart';
import '../feature/reports/controller/report_cubit.dart';
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

  // laborCubit
  sl.registerFactory<LaborCubit>(() => LaborCubit(
        firebaseAuth: sl<FirebaseAuth>(),
        firestore: sl<FirebaseFirestore>(),
      ));

  // inventoryCubit
  sl.registerFactory<InventoryCubit>(() => InventoryCubit(
        firebaseAuth: sl<FirebaseAuth>(),
        firestore: sl<FirebaseFirestore>(),
      ));

  // reportsCubit
  sl.registerFactory<ReportsCubit>(() => ReportsCubit(
        firestore: sl<FirebaseFirestore>(),
      ));
}
