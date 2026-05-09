import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';
import '../models/category_model.dart';
import '../widgets/custom_button.dart';
import '../data/sample_questions.dart';
import 'quiz_screen.dart';

class QuizSetupScreen extends StatefulWidget {
  final CategoryModel category;

  const QuizSetupScreen({super.key, required this.category});

  @override
  State<QuizSetupScreen> createState() => _QuizSetupScreenState();
}

class _QuizSetupScreenState extends State<QuizSetupScreen> {
  String _difficulty = 'Medium';
  int _questionCount = 10;

  @override
  Widget build(BuildContext context) {
    final cat = widget.category;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: cat.color,
            expandedHeight: 200,
            pinned: true,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cat.color, cat.darkColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Text(cat.emoji,
                          style: const TextStyle(fontSize: 60)),
                      const SizedBox(height: 8),
                      Text(
                        cat.name,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${cat.totalQuestions} Questions Available',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Setup Options ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // ── Difficulty ─────────────────────────────────
                  Text('Difficulty',
                      style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),

                  const SizedBox(height: 14),

                  Row(
                    children: ['Easy', 'Medium', 'Hard'].map((diff) {
                      final selected = _difficulty == diff;
                      final color = diff == 'Easy'
                          ? const Color(0xFF4CAF50)
                          : diff == 'Medium'
                              ? const Color(0xFFFF9800)
                              : const Color(0xFFE53935);

                      return Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _difficulty = diff),
                          child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: selected
                                  ? color.withOpacity(0.2)
                                  : AppColors.cardBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selected ? color : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  diff == 'Easy'
                                      ? '😊'
                                      : diff == 'Medium'
                                          ? '😤'
                                          : '🔥',
                                  style: const TextStyle(fontSize: 24),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  diff,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: selected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: selected
                                        ? color
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 28),

                  // ── Number of Questions ────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Questions',
                          style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary)),
                      Text('$_questionCount',
                          style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: cat.color)),
                    ],
                  ),

                  Slider(
                    value: _questionCount.toDouble(),
                    min: 5,
                    max: 20,
                    divisions: 3,
                    activeColor: cat.color,
                    inactiveColor: AppColors.cardBg,
                    label: '$_questionCount',
                    onChanged: (val) =>
                        setState(() => _questionCount = val.toInt()),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ['5', '10', '15', '20']
                        .map((n) => Text(n,
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppColors.textHint)))
                        .toList(),
                  ),

                  const SizedBox(height: 32),

                  // ── Summary Card ───────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: cat.color.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _summaryItem('📚', '$_questionCount', 'Questions'),
                        _divider(),
                        _summaryItem(
                          '⚡',
                          _difficulty == 'Easy'
                              ? '30s'
                              : _difficulty == 'Medium'
                                  ? '20s'
                                  : '15s',
                          'Per Question',
                        ),
                        _divider(),
                        _summaryItem(
                          '🪙',
                          _difficulty == 'Easy'
                              ? '5'
                              : _difficulty == 'Medium'
                                  ? '10'
                                  : '20',
                          'Coins/Q',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Start Button ───────────────────────────────
                  CustomButton(
                    text: '🚀  Start Quiz',
                    color: cat.color,
                    onPressed: () {
                      final questions = getQuestionsForCategory(
                        widget.category.id,
                        _questionCount,
                        _difficulty,
                      );

                      if (questions.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No questions available for this selection.'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizScreen(
                            category: widget.category,
                            questions: questions,
                            difficulty: _difficulty,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _divider() => Container(
        height: 40,
        width: 1,
        color: AppColors.inputBg,
      );
}