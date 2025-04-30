import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:zera3a/feature/home/Bloc/plot_cubit.dart';
import '../feature/auth/auth_cubit.dart';

final GetIt sl = GetIt.instance;

Future<void> init() async {
  // Firebase Auth (singleton)
  sl.registerLazySingleton<FirebaseAuth>(
        () => FirebaseAuth.instance,
  );

  // Flutter Secure Storage (singleton)
  sl.registerLazySingleton<FlutterSecureStorage>(
        () => const FlutterSecureStorage(),
  );

  // FirebaseFirestore (singleton)
  sl.registerLazySingleton<FirebaseFirestore>(
        () => FirebaseFirestore.instance,
  );

  // AuthCubit
  sl.registerSingleton<AuthCubit>(
    AuthCubit(
      firebaseAuth: sl<FirebaseAuth>(),
      flutterSecure: sl<FlutterSecureStorage>(),
    ),
  );


  // PlotCubit
  sl.registerSingleton<PlotCubit>(
    PlotCubit(
      firebaseAuth: sl<FirebaseAuth>(),
      firestore: sl<FirebaseFirestore>(),
    ),
  );
}