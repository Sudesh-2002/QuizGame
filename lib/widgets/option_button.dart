import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';

class OptionButton extends StatelessWidget {
  final String text;
  final String label; // A, B, C, D
  final bool isSelected;
  final bool isCorrect;
  final bool isWrong;
  final bool isHidden;
  final bool isDisabled;
  final VoidCallback onTap;

  const OptionButton({
    super.key,
    required this.text,
    required this.label,
    required this.onTap,
    this.isSelected = false,
    this.isCorrect = false,
    this.isWrong = false,
    this.isHidden = false,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isHidden) return const SizedBox(height: 60);

    Color bgColor = AppColors.cardBg;
    Color borderColor = AppColors.inputBg;
    Color textColor = AppColors.textPrimary;
    Color labelBg = AppColors.inputBg;
    IconData? trailingIcon;

    if (isCorrect) {
      bgColor = AppColors.success.withOpacity(0.15);
      borderColor = AppColors.success;
      textColor = AppColors.success;
      labelBg = AppColors.success;
      trailingIcon = Icons.check_circle_rounded;
    } else if (isWrong) {
      bgColor = AppColors.error.withOpacity(0.15);
      borderColor = AppColors.error;
      textColor = AppColors.error;
      labelBg = AppColors.error;
      trailingIcon = Icons.cancel_rounded;
    } else if (isSelected) {
      bgColor = AppColors.primary.withOpacity(0.15);
      borderColor = AppColors.primary;
      textColor = AppColors.primary;
      labelBg = AppColors.primary;
    }

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Row(
          children: [
            // Label (A/B/C/D)
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: labelBg,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(width: 14),

            // Option text
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),

            // Trailing icon
            if (trailingIcon != null)
              Icon(trailingIcon, color: textColor, size: 22),
          ],
        ),
      ),
    );
  }
}