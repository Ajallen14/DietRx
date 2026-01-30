import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/database_helper.dart';
import 'scanner_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isDbReady = false;

  @override
  void initState() {
    super.initState();
    _initDatabaseInBackground();
  }

  // Silent Background Init
  Future<void> _initDatabaseInBackground() async {
    try {
      await DatabaseHelper().database;
      if (mounted) {
        setState(() {
          _isDbReady = true;
        });
      }
    } catch (e) {
      print("Database Init Failed: $e");
    }
  }

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
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),

      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Home Screen",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isDbReady
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ScannerScreen(),
                  ),
                );
              }
            : null,

        backgroundColor: _isDbReady
            ? const Color(0xFF1B4D3E)
            : Colors.grey[800],
        foregroundColor: Colors.white,

        icon: _isDbReady
            ? const Icon(Icons.qr_code_scanner)
            : const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white54,
                ),
              ),

        label: Text(_isDbReady ? "Scan Now" : "Readying..."),
      ),
    );
  }
}
