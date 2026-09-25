import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:turiva/widgets/air_control_host.dart';
import 'utils/colors.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/main_screen.dart';
import 'screens/hand_control_screen.dart';
import 'services/notification_service.dart';
import 'widgets/air_cursor.dart';
import 'widgets/air_control_host.dart';
import 'services/air_control_engine.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDDKlIwhqR51p9Vb0tnwlbWJnpgV0MUcXk",
      appId: "1:749360118137:android:cb2a144e34389a062497a8",
      messagingSenderId: "749360118137",
      projectId: "turiva",
      authDomain: "turiva.firebaseapp.com",
      storageBucket: "turiva.firebasestorage.app",
    ),
  );

  // ⭐️ Connect to Functions Emulator (kwa testing tu)
  FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);

  // Start listening for notifications
  FirebaseAuth.instance.authStateChanges().listen((user) {
    if (user != null) {
      NotificationService().listenForNewNotifications(user.uid);
    }
  });

  runApp(const TurivaApp());

}

class TurivaApp extends StatelessWidget {
  const TurivaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TURIVA',
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.accentGold,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentGold,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),


      builder: (context, child) {
        return AirControlHost(
          child: Stack(
            children: [
              child ?? const SizedBox.shrink(),
              const AirCursor(),
            ],
          ),
        );
      },
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const MainScreen(),
        '/hand-control': (context) => const HandControlScreen(),
      },
    );
  }
}