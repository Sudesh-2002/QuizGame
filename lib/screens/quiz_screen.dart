import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';
import '../models/category_model.dart';
import '../models/question_model.dart';
import '../providers/auth_provider.dart';
import '../providers/quiz_provider.dart';
import '../services/ad_service.dart';
import '../services/quiz_service.dart';
import '../widgets/audience_votes_widget.dart';
import '../widgets/option_button.dart';
import '../widgets/quiz_timer.dart';
import 'result_screen.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final CategoryModel category;
  final List<QuestionModel> questions;
  final String difficulty;

  const QuizScreen({
    super.key,
    required this.category,
    required this.questions,
    required this.difficulty,
  });

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  int _timerKey = 0;
  bool _showExplanation = false;

  int get _timerSeconds {
    switch (widget.difficulty) {
      case 'Easy': return 30;
      case 'Hard': return 15;
      default: return 20;
    }
  }

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _onAnswer(QuizNotifier notifier, QuizState state, int index) {
    if (state.selectedAnswers[state.currentIndex] != null) return;
    notifier.answerQuestion(index, widget.difficulty);
    setState(() => _showExplanation = true);
  }

  void _onNext(QuizNotifier notifier, QuizState state) {
    if (state.isLastQuestion) {
      _finishQuiz(state);
      return;
    }
    notifier.nextQuestion();
    setState(() {
      _showExplanation = false;
      _timerKey++;
    });
    _slideController
      ..reset()
      ..forward();
  }

  Future<void> _finishQuiz(QuizState state) async {
    final user = ref.read(userModelProvider);
    if (user != null) {
      await QuizService().saveQuizResult(
        uid: user.uid,
        categoryId: widget.category.id,
        difficulty: widget.difficulty,
        score: state.score,
        coinsEarned: state.coins,
        correct: state.correctCount,
        total: state.totalQuestions,
      );
    }
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            category: widget.category,
            state: state,
            difficulty: widget.difficulty,
          ),
        ),
      );
    }
  }

  // ── Show ad to restore lifeline ──────────────────────────────
  void _watchAdForLifeline(
    String lifelineName,
    VoidCallback onRestored,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '📺 Watch Ad?',
          style: GoogleFonts.poppins(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Watch a short ad to restore your $lifelineName lifeline!',
          style:
              GoogleFonts.poppins(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style:
                    GoogleFonts.poppins(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (!AdService().isRewardedReady) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ad not ready yet, try again shortly!'),
                    backgroundColor: AppColors.warning,
                  ),
                );
                return;
              }
              AdService().showRewardedAd(
                onRewarded: () {
                  onRestored();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            '✅ $lifelineName lifeline restored!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary),
            child: Text('Watch Ad 📺',
                style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmQuit() async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.cardBg,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Text('Quit Quiz?',
                style: GoogleFonts.poppins(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold)),
            content: Text(
              'Your progress will be lost. Are you sure?',
              style:
                  GoogleFonts.poppins(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Continue',
                    style:
                        GoogleFonts.poppins(color: AppColors.primary)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error),
                child: Text('Quit',
                    style:
                        GoogleFonts.poppins(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final quizNotifier =
        ref.read(quizProvider(widget.questions).notifier);
    final state = ref.watch(quizProvider(widget.questions));

    if (state.isFinished) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _finishQuiz(state);
      });
    }

    final question = state.currentQuestion;
    final selectedAnswer = state.selectedAnswers[state.currentIndex];
    final isAnswered = selectedAnswer != null;
    final labels = ['A', 'B', 'C', 'D'];

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final quit = await _confirmQuit();
        if (quit && mounted) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // ── Top Bar ───────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final quit = await _confirmQuit();
                        if (quit && mounted) Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.close_rounded,
                            color: AppColors.textSecondary, size: 20),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${state.currentIndex + 1}/${state.totalQuestions}',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                widget.category.name,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: (state.currentIndex + 1) /
                                  state.totalQuestions,
                              backgroundColor: AppColors.cardBg,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  widget.category.color),
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    QuizTimer(
                      key: ValueKey(_timerKey),
                      seconds: _timerSeconds,
                      isAnswered: isAnswered,
                      onTimeUp: () {
                        quizNotifier.timeUp();
                        setState(() => _showExplanation = true);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ── Score & Coins ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _infoChip('⭐', '${state.score}', 'Score'),
                    _infoChip('🪙', '${state.coins}', 'Coins'),
                    _infoChip(
                        '✅', '${state.correctCount}', 'Correct'),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Question & Options ────────────────────────────
              Expanded(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        // Question box
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                widget.category.color,
                                widget.category.darkColor
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: widget.category.color
                                    .withOpacity(0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(widget.category.emoji,
                                  style:
                                      const TextStyle(fontSize: 36)),
                              const SizedBox(height: 12),
                              Text(
                                'Question ${state.currentIndex + 1}',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.white60,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                question.question,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── Lifelines ─────────────────────────────
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            // 50/50
                            _lifelineButton(
                              label: '50/50',
                              emoji: '⚡',
                              used: state.fiftyFiftyUsed,
                              onTap: isAnswered
                                  ? null
                                  : state.fiftyFiftyUsed
                                      ? () => _watchAdForLifeline(
                                            '50/50',
                                            quizNotifier.resetFiftyFifty,
                                          )
                                      : quizNotifier.useFiftyFifty,
                              needsAd: state.fiftyFiftyUsed,
                            ),
                            const SizedBox(width: 8),

                            // Ask the Audience
                            _lifelineButton(
                              label: 'Audience',
                              emoji: '👥',
                              used: state.askAudienceUsed,
                              onTap: isAnswered
                                  ? null
                                  : state.askAudienceUsed
                                      ? () => _watchAdForLifeline(
                                            'Ask Audience',
                                            quizNotifier
                                                .resetAskAudience,
                                          )
                                      : quizNotifier.useAskAudience,
                              needsAd: state.askAudienceUsed,
                            ),
                            const SizedBox(width: 8),

                            // Skip
                            _lifelineButton(
                              label: 'Skip',
                              emoji: '⏭️',
                              used: state.skipUsed,
                              onTap: isAnswered
                                  ? null
                                  : state.skipUsed
                                      ? () => _watchAdForLifeline(
                                            'Skip',
                                            quizNotifier.resetSkip,
                                          )
                                      : quizNotifier.skipQuestion,
                              needsAd: state.skipUsed,
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // ── Audience Votes ────────────────────────
                        if (state.audienceVotes.isNotEmpty &&
                            !isAnswered) ...[
                          AudienceVotesWidget(
                            votes: state.audienceVotes,
                            options: question.options,
                            hiddenOptions: state.hiddenOptions,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // ── Options ───────────────────────────────
                        ...question.options.asMap().entries.map(
                          (entry) {
                            final i = entry.key;
                            final text = entry.value;
                            final isHidden =
                                state.hiddenOptions.contains(i);
                            final isSelected = selectedAnswer == i;
                            final isCorrectOption =
                                i == question.correctIndex;

                            return OptionButton(
                              text: text,
                              label: labels[i],
                              isHidden: isHidden,
                              isDisabled: isAnswered,
                              isSelected:
                                  isSelected && !isAnswered,
                              isCorrect:
                                  isAnswered && isCorrectOption,
                              isWrong: isAnswered &&
                                  isSelected &&
                                  !isCorrectOption,
                              onTap: () => _onAnswer(
                                  quizNotifier, state, i),
                            );
                          },
                        ),

                        // ── Explanation ───────────────────────────
                        if (_showExplanation &&
                            isAnswered &&
                            question.explanation != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.cardBg,
                              borderRadius:
                                  BorderRadius.circular(16),
                              border: Border.all(
                                  color: AppColors.primary
                                      .withOpacity(0.3)),
                            ),
                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Text('💡',
                                    style:
                                        TextStyle(fontSize: 18)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    question.explanation!,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color:
                                          AppColors.textSecondary,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),

                        // ── Next Button ───────────────────────────
                        if (isAnswered)
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: () =>
                                  _onNext(quizNotifier, state),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    widget.category.color,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(16),
                                ),
                                elevation: 4,
                                shadowColor: widget.category.color
                                    .withOpacity(0.4),
                              ),
                              child: Text(
                                state.isLastQuestion
                                    ? '🏁  See Results'
                                    : 'Next Question →',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(String emoji, String value, String label) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _lifelineButton({
    required String label,
    required String emoji,
    required bool used,
    required bool needsAd,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: needsAd
              ? const Color(0xFFFF9800).withOpacity(0.1)
              : AppColors.primary.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: needsAd
                ? const Color(0xFFFF9800)
                : AppColors.primary,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              needsAd ? '📺' : emoji,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 2),
            Text(
              needsAd ? 'Ad' : label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: needsAd
                    ? const Color(0xFFFF9800)
                    : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}