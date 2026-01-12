import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'splash_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'health_profile_screen.dart';

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B4D3E)),
        useMaterial3: true,
      ),
      home: const DietRxSplashScreen(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // 1. Check if User is Logged In
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        
        // Waiting for Auth...
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // 2. User IS Logged In -> Check Database for Profile
        if (authSnapshot.hasData) {
          final User user = authSnapshot.data!;

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('Health_Profiles')
                .doc(user.uid)
                .get(),
            
            builder: (context, dbSnapshot) {
              // Waiting for Database...(Loading screen)
              if (dbSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  backgroundColor: Color(0xFF1B4D3E),
                  body: Center(child: CircularProgressIndicator(color: Colors.white)),
                );
              }

              // 3. LOGIC DECISION
              if (dbSnapshot.hasData && dbSnapshot.data!.exists) {
                // Profile Exists -> Go Home
                return const HomeScreen();
              } else {
                // Profile Missing -> Go Setup Profile
                return const HealthProfileScreen();
              }
            },
          );
        }

        // 4. User is NOT Logged In -> Go Login
        return const LoginScreen();
      },
    );
  }
}