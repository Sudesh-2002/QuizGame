import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/question_model.dart';

class QuizState {
  final List<QuestionModel> questions;
  final int currentIndex;
  final List<int?> selectedAnswers;
  final int score;
  final int coins;
  final bool isFinished;
  final bool fiftyFiftyUsed;
  final bool skipUsed;
  final List<int> hiddenOptions; // for 50/50 lifeline

  QuizState({
    required this.questions,
    this.currentIndex = 0,
    required this.selectedAnswers,
    this.score = 0,
    this.coins = 0,
    this.isFinished = false,
    this.fiftyFiftyUsed = false,
    this.skipUsed = false,
    this.hiddenOptions = const [],
  });

  QuestionModel get currentQuestion => questions[currentIndex];
  bool get isLastQuestion => currentIndex == questions.length - 1;
  int get totalQuestions => questions.length;
  int get correctCount =>
      selectedAnswers.asMap().entries.where((e) {
        final i = e.key;
        final ans = e.value;
        return ans != null && ans == questions[i].correctIndex;
      }).length;

  QuizState copyWith({
    int? currentIndex,
    List<int?>? selectedAnswers,
    int? score,
    int? coins,
    bool? isFinished,
    bool? fiftyFiftyUsed,
    bool? skipUsed,
    List<int>? hiddenOptions,
  }) {
    return QuizState(
      questions: questions,
      currentIndex: currentIndex ?? this.currentIndex,
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
      score: score ?? this.score,
      coins: coins ?? this.coins,
      isFinished: isFinished ?? this.isFinished,
      fiftyFiftyUsed: fiftyFiftyUsed ?? this.fiftyFiftyUsed,
      skipUsed: skipUsed ?? this.skipUsed,
      hiddenOptions: hiddenOptions ?? this.hiddenOptions,
    );
  }
}

class QuizNotifier extends StateNotifier<QuizState> {
  QuizNotifier(List<QuestionModel> questions)
      : super(QuizState(
          questions: questions,
          selectedAnswers: List.filled(questions.length, null),
        ));

  // Answer a question
  void answerQuestion(int optionIndex, String difficulty) {
    if (state.selectedAnswers[state.currentIndex] != null) return;

    final isCorrect =
        optionIndex == state.currentQuestion.correctIndex;

    final coinsEarned = isCorrect
        ? (difficulty == 'Easy' ? 5 : difficulty == 'Medium' ? 10 : 20)
        : 0;

    final scoreEarned = isCorrect ? 100 : 0;

    final newAnswers = List<int?>.from(state.selectedAnswers);
    newAnswers[state.currentIndex] = optionIndex;

    state = state.copyWith(
      selectedAnswers: newAnswers,
      score: state.score + scoreEarned,
      coins: state.coins + coinsEarned,
    );
  }

  // Go to next question
  void nextQuestion() {
    if (state.isLastQuestion) {
      state = state.copyWith(isFinished: true);
      return;
    }
    state = state.copyWith(
      currentIndex: state.currentIndex + 1,
      hiddenOptions: [],
    );
  }

  // Skip question (lifeline)
  void skipQuestion() {
    if (state.skipUsed) return;
    final newAnswers = List<int?>.from(state.selectedAnswers);
    newAnswers[state.currentIndex] = -1; // -1 = skipped

    state = state.copyWith(
      skipUsed: true,
      selectedAnswers: newAnswers,
    );

    Future.delayed(const Duration(milliseconds: 300), nextQuestion);
  }

  // 50/50 lifeline
  void useFiftyFifty() {
    if (state.fiftyFiftyUsed) return;

    final correctIndex = state.currentQuestion.correctIndex;
    final wrongOptions = [0, 1, 2, 3]
        .where((i) => i != correctIndex)
        .toList()
      ..shuffle();

    // Hide 2 wrong options
    final toHide = wrongOptions.take(2).toList();

    state = state.copyWith(
      fiftyFiftyUsed: true,
      hiddenOptions: toHide,
    );
  }

  // Time ran out
  void timeUp() {
    if (state.selectedAnswers[state.currentIndex] != null) return;
    final newAnswers = List<int?>.from(state.selectedAnswers);
    newAnswers[state.currentIndex] = -2; // -2 = time up
    state = state.copyWith(selectedAnswers: newAnswers);
  }

  // Finish quiz manually
  void finishQuiz() {
    state = state.copyWith(isFinished: true);
  }
}

final quizProvider =
    StateNotifierProvider.family<QuizNotifier, QuizState, List<QuestionModel>>(
  (ref, questions) => QuizNotifier(questions),
);