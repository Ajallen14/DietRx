import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'scanner_screen.dart';
import 'main.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("DietRx", style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: const Color(0xFF1B4D3E),
        iconTheme: const IconThemeData(color: Colors.white),

        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: () async {
              // 1. Sign Out
              await FirebaseAuth.instance.signOut();

              // 2. NAVIGATE DIRECTLY TO AUTHWRAPPER
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const AuthWrapper()),
                  (Route<dynamic> route) => false,
                );
              }
            },
          ),
        ],
      ),

      body: const Center(
        child: Text(
          "U r Logged in",
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ScannerScreen()),
          );
        },
        backgroundColor: const Color(0xFF1B4D3E),
        icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
        label: const Text("Scan Now", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
