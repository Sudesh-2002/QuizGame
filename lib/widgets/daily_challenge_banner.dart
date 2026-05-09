import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DailyChallengeBanner extends StatelessWidget {
  final VoidCallback onTap;
  final bool isCompleted;

  const DailyChallengeBanner({
    super.key,
    required this.onTap,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isCompleted
                ? [const Color(0xFF4CAF50), const Color(0xFF388E3C)]
                : [const Color(0xFFFF9800), const Color(0xFFF44336)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (isCompleted
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFFF9800))
                  .withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                isCompleted ? '✅' : '🔥',
                style: const TextStyle(fontSize: 28),
              ),
            ),

            const SizedBox(width: 16),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCompleted ? 'Challenge Done!' : 'Daily Challenge',
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    isCompleted
                        ? 'Come back tomorrow for a new challenge'
                        : 'Answer 10 questions • Earn 50 coins',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            // Arrow
            if (!isCompleted)
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white70,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}