import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Center(
        child: Text(
          '🎮 Home Screen\nComing in Step 3!',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 24,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}