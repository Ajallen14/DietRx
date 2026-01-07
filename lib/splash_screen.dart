import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart'; // Import main.dart to access AuthWrapper

class DietRxSplashScreen extends StatefulWidget {
  const DietRxSplashScreen({super.key});

  @override
  State<DietRxSplashScreen> createState() => _DietRxSplashScreenState();
}

class _DietRxSplashScreenState extends State<DietRxSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _logoScaleAnimation;

  late AnimationController _textController;
  late Animation<double> _textFadeAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Setup Logo Animation
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _logoScaleAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOutBack, // Bouncy effect
    );

    // 2. Setup Text Animation
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _textFadeAnimation = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeIn,
    );

    // 3. Run the sequence
    _startAnimationSequence();
  }

  Future<void> _startAnimationSequence() async {
    // Start Logo
    await _logoController.forward();

    _textController.forward();

    await Future.delayed(const Duration(seconds: 2));

    // 4. Navigate to AuthWrapper (Checks login status)
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthWrapper()),
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B4D3E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ANIMATED LOGO
            ScaleTransition(
              scale: _logoScaleAnimation,
              child: Image.asset(
                'assets/images/logo_icon.png',
                width: 150, 
                height: 150,
              ),
            ),

            const SizedBox(height: 20),

            // ANIMATED TEXT
            FadeTransition(
              opacity: _textFadeAnimation,
              child: Text(
                "DietRx",
                style: GoogleFonts.poppins(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
