import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';
import '../models/category_model.dart';
import '../providers/quiz_provider.dart';
import '../providers/stats_provider.dart';
import 'home_screen.dart';
import '../providers/leaderboard_provider.dart';


class ResultScreen extends ConsumerWidget {
  final CategoryModel category;
  final QuizState state;
  final String difficulty;

  const ResultScreen({
    super.key,
    required this.category,
    required this.state,
    required this.difficulty,
  });

  String get _grade {
    final pct = state.correctCount / state.totalQuestions;
    if (pct == 1.0) return 'S';
    if (pct >= 0.8) return 'A';
    if (pct >= 0.6) return 'B';
    if (pct >= 0.4) return 'C';
    return 'D';
  }

  String get _gradeEmoji {
    switch (_grade) {
      case 'S': return '🏆';
      case 'A': return '🌟';
      case 'B': return '😊';
      case 'C': return '😐';
      default:  return '😢';
    }
  }

  String get _gradeMessage {
    switch (_grade) {
      case 'S': return 'Perfect Score!';
      case 'A': return 'Excellent!';
      case 'B': return 'Good Job!';
      case 'C': return 'Keep Practicing!';
      default:  return 'Try Again!';
    }
  }

  Color get _gradeColor {
    switch (_grade) {
      case 'S': return const Color(0xFFFFD700);
      case 'A': return AppColors.success;
      case 'B': return AppColors.primary;
      case 'C': return AppColors.warning;
      default:  return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accuracy =
        (state.correctCount / state.totalQuestions * 100).round();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // ── Grade Circle ─────────────────────────────────────
              Text(_gradeEmoji,
                  style: const TextStyle(fontSize: 60)),

              const SizedBox(height: 16),

              Text(
                _gradeMessage,
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              Text(
                category.name,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 28),

              // ── Grade Badge ───────────────────────────────────────
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _gradeColor.withOpacity(0.15),
                  border: Border.all(color: _gradeColor, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: _gradeColor.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _grade,
                    style: GoogleFonts.poppins(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: _gradeColor,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ── Stats Grid ────────────────────────────────────────
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _resultCard('✅ Correct',
                      '${state.correctCount}/${state.totalQuestions}',
                      AppColors.success),
                  _resultCard('🎯 Accuracy',
                      '$accuracy%',
                      AppColors.primary),
                  _resultCard('⭐ Score',
                      '${state.score}',
                      const Color(0xFFFFD700)),
                  _resultCard('🪙 Coins Earned',
                      '+${state.coins}',
                      const Color(0xFFFF9800)),
                ],
              ),

              const SizedBox(height: 20),

              // ── Answers Review ────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Answer Review',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...state.questions.asMap().entries.map((entry) {
                      final i = entry.key;
                      final q = entry.value;
                      final ans = state.selectedAnswers[i];
                      final isCorrect = ans == q.correctIndex;
                      final isSkipped = ans == -1;
                      final isTimeUp = ans == -2;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Text(
                              isSkipped || isTimeUp
                                  ? '⏭️'
                                  : isCorrect
                                      ? '✅'
                                      : '❌',
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                q.question,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Buttons ───────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    // Invalidate leaderboard so it refetches on next open
                    ref.invalidate(globalLeaderboardProvider);
                    ref.invalidate(weeklyLeaderboardProvider);
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: category.color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    '🏠  Back to Home',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: category.color),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    '🔄  Play Again',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: category.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resultCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}