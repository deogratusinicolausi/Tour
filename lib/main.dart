import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
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
    print('🔥 Firebase initialized successfully');
  } catch (e) {
    print('🔥 Firebase initialization error: $e');
  }

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
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}