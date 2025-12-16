import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'home_screen.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); 
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DietRx',
      // STREAM BUILDER: This is the "Auth Check" logic
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // 1. If the snapshot has data, it means a user is ALREADY logged in.
          if (snapshot.hasData) {
            return const HomeScreen();
          }
          // 2. Otherwise, show the Login Screen.
          return const LoginScreen();
        },
      ),
    );
  }
}