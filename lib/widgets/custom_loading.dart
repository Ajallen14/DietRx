import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomLoading extends StatelessWidget {
  final String message;
  final Color textColor;

  const CustomLoading({
    super.key,
    this.message = "Loading...",
    this.textColor = const Color(0xFF557B3E),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // --- THE LOTTIE ANIMATION ---
          Lottie.asset(
            'assets/animations/food_loading.json',
            width: 110,
            height: 110,
            fit: BoxFit.contain,
            delegates: LottieDelegates(
              values: [
                ValueDelegate.colorFilter(
                  const ['**'],
                  value: const ColorFilter.mode(
                    Color(0xFF8CC63F),
                    BlendMode.srcATop,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // --- THE LOADING TEXT ---
          Text(
            message,
            style: GoogleFonts.poppins(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
