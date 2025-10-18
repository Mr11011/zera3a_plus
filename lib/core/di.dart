import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../feature/auth/auth_cubit.dart';
import '../feature/cashFlow/controller/cash_flow_cubit.dart';
import '../feature/home/controller/plot_cubit.dart';
import '../feature/home/general_reports/general_reporst_cubit.dart';
import '../feature/inventory/controller/inventory_cubit.dart';
import '../feature/inventory/generalInventory/controlller/general_inventory_cubit.dart';
import '../feature/irrigation/irrigation_cubit.dart';
import '../feature/reports/controller/report_cubit.dart';
import '../feature/workers/workers_cubit.dart';

final GetIt sl = GetIt.instance;

Future<void> init() async {
  // Firebase Auth (singleton)
  sl.registerLazySingleton<FirebaseAuth>(
    () => FirebaseAuth.instance,
  );
  // SharedPreferences (singleton)
  SharedPreferences prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);

  // Initialize Firestore with custom settings BEFORE registering it
  final firestore = FirebaseFirestore.instance;
  firestore.settings = const Settings(
      persistenceEnabled: true, cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED);

  // FirebaseFirestore (singleton)
  sl.registerLazySingleton<FirebaseFirestore>(
    () => firestore,
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

  // generalReportsCubit
  sl.registerFactory<GeneralReportsCubit>(() => GeneralReportsCubit(
        firestore: sl<FirebaseFirestore>(),
      ));

  // generalInventoryCubit
  sl.registerFactory<GeneralInventoryCubit>(() => GeneralInventoryCubit(
        firestore: sl<FirebaseFirestore>(),
        firebaseAuth: sl<FirebaseAuth>(),
      ));

  // cashFlowCubit
  sl.registerFactory<CashFlowCubit>(() => CashFlowCubit(
        firestore: sl<FirebaseFirestore>(),
        firebaseAuth: sl<FirebaseAuth>(),
      ));
}
