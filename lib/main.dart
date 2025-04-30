import 'package:bloc/bloc.dart';
import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zera3a/feature/auth/signIn_screen.dart';
import 'package:zera3a/feature/home/views/home_screen.dart';
import 'core/blocObserver.dart';
import 'core/di.dart';
import 'feature/auth/signUp_Screen.dart';
import 'feature/home/Bloc/plot_cubit.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Bloc.observer = MyBlocObserver();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await init();

  final secureStorage = sl<FlutterSecureStorage>();
  final token = await secureStorage.read(key: "authToken");

  runApp(DevicePreview(
    enabled: kDebugMode,
    builder: (context) => MyApp(isLoggedIn: token != null),
  ));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (BuildContext context) { return sl<PlotCubit>(); },
      child: MaterialApp(
        locale: DevicePreview.locale(context),
        builder: DevicePreview.appBuilder,
        theme: ThemeData(fontFamily: GoogleFonts.readexPro().fontFamily
            /*
                KATIBEH
                Cairo PLAY
                Amiri
                readex
                lalezar
                Lateef
                Rakkas
                Alexandria
                El Messiri
                Marhey

                 */
            ),
        title: 'إدارة المزرعة',
        home: isLoggedIn ? HomePage() : OnboardingScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.greenAccent,
      body: Stack(
        fit: StackFit.expand, // Makes the background fill the screen
        children: [
          // Background Image
          Image.asset(
            'assets/images/background4.png',
            fit: BoxFit.cover, // Ensures the image covers the screen
          ),
          // Overlay Content
          Container(
            color: Colors.black.withValues(alpha: 0.30),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Welcome Text
                  Text(
                    'مرحبًا بك في إدارة مزرعتك',
                    style: TextStyle(
                      fontSize: 28,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'تابع مصاريف مزرعتك بسهولة',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 40),
                  // Start Button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SignInScreen()));
                    },
                    style: ElevatedButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        backgroundColor: Colors.green),
                    child: Text(
                      'ابدأ',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
