import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // <-- required for DefaultFirebaseOptions
import 'package:provider/provider.dart';
import 'auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:first_project/calorie_tracker_provider.dart';
import 'package:first_project/login_page.dart';
import 'package:first_project/home_page.dart';
import 'package:first_project/map_screen.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => CalorieTrackerProvider(),
      child: const MyApp(),
    ),
  );
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CalTrack',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF4CAF50),
      ),
      home: StreamBuilder<User?>(
        stream: AuthService().authStateChanges,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snap.data == null) {
            return const LoginPage();
          }
          return const HomePage();
        },
      ),
    );
  }
}