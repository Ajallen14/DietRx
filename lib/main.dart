import 'package:dietrx/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'widgets/custom_loading.dart';
import 'screens/health_profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(
    ThemeMode.light,
  );

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'DietRx',
          themeMode: currentMode,

          // --- LIGHT THEME ---
          theme: ThemeData(
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1B4D3E),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),

          // --- DARK THEME ---
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1B4D3E),
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF121212),
            useMaterial3: true,
          ),

          home: const DietRxSplashScreen(),
        );
      },
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
          return const Scaffold(
            backgroundColor: Colors.white,
            body: CustomLoading(
              message: "Preparing DietRx...",
              textColor: Color(0xFF8CC63F),
            ),
          );
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
              // Waiting for Database (Loading screen)
              if (dbSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  backgroundColor: Colors.white,
                  body: CustomLoading(
                    message: "Loading Profile...",
                    textColor: Color(0xFF8CC63F),
                  ),
                );
              }

              // 3. LOGIC DECISION
              if (dbSnapshot.hasData && dbSnapshot.data!.exists) {
                // Profile Exists -> Go Home
                return const MainScreen();
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
