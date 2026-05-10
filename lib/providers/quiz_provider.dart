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
  final bool askAudienceUsed;
  final List<int> hiddenOptions;
  final Map<int, int> audienceVotes; // option index → percentage

  QuizState({
    required this.questions,
    this.currentIndex = 0,
    required this.selectedAnswers,
    this.score = 0,
    this.coins = 0,
    this.isFinished = false,
    this.fiftyFiftyUsed = false,
    this.skipUsed = false,
    this.askAudienceUsed = false,
    this.hiddenOptions = const [],
    this.audienceVotes = const {},
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
    bool? askAudienceUsed,
    List<int>? hiddenOptions,
    Map<int, int>? audienceVotes,
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
      askAudienceUsed: askAudienceUsed ?? this.askAudienceUsed,
      hiddenOptions: hiddenOptions ?? this.hiddenOptions,
      audienceVotes: audienceVotes ?? this.audienceVotes,
    );
  }
}

class QuizNotifier extends StateNotifier<QuizState> {
  QuizNotifier(List<QuestionModel> questions)
      : super(QuizState(
          questions: questions,
          selectedAnswers: List.filled(questions.length, null),
        ));

  void answerQuestion(int optionIndex, String difficulty) {
    if (state.selectedAnswers[state.currentIndex] != null) return;

    final isCorrect = optionIndex == state.currentQuestion.correctIndex;
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
      audienceVotes: {}, // clear votes on answer
    );
  }

  void nextQuestion() {
    if (state.isLastQuestion) {
      state = state.copyWith(isFinished: true);
      return;
    }
    state = state.copyWith(
      currentIndex: state.currentIndex + 1,
      hiddenOptions: [],
      audienceVotes: {},
    );
  }

  void skipQuestion() {
    if (state.skipUsed) return;
    final newAnswers = List<int?>.from(state.selectedAnswers);
    newAnswers[state.currentIndex] = -1;
    state = state.copyWith(
      skipUsed: true,
      selectedAnswers: newAnswers,
    );
    Future.delayed(const Duration(milliseconds: 300), nextQuestion);
  }

  void useFiftyFifty() {
    if (state.fiftyFiftyUsed) return;
    final correctIndex = state.currentQuestion.correctIndex;
    final wrongOptions = [0, 1, 2, 3]
        .where((i) => i != correctIndex)
        .toList()
      ..shuffle();
    final toHide = wrongOptions.take(2).toList();
    state = state.copyWith(
      fiftyFiftyUsed: true,
      hiddenOptions: toHide,
    );
  }

  // ── Ask the Audience ─────────────────────────────────────────
  void useAskAudience() {
    if (state.askAudienceUsed) return;

    final correctIndex = state.currentQuestion.correctIndex;
    final hiddenOptions = state.hiddenOptions;

    // Available options (not hidden by 50/50)
    final available = [0, 1, 2, 3]
        .where((i) => !hiddenOptions.contains(i))
        .toList();

    // Generate realistic voting percentages
    // Correct answer always gets highest percentage (50-75%)
    final votes = <int, int>{};
    int remaining = 100;

    // Correct answer gets 50-75%
    final correctVote = 50 + (DateTime.now().millisecond % 26);
    votes[correctIndex] = correctVote;
    remaining -= correctVote;

    // Distribute remaining among wrong options
    final wrongOptions =
        available.where((i) => i != correctIndex).toList()..shuffle();

    for (int i = 0; i < wrongOptions.length; i++) {
      if (i == wrongOptions.length - 1) {
        votes[wrongOptions[i]] = remaining;
      } else {
        final share = remaining ~/ (wrongOptions.length - i);
        final variation = (DateTime.now().microsecond % 5) - 2;
        final vote = (share + variation).clamp(1, remaining - (wrongOptions.length - i - 1));
        votes[wrongOptions[i]] = vote;
        remaining -= vote;
      }
    }

    // Fill hidden options with 0
    for (int i = 0; i < 4; i++) {
      if (!votes.containsKey(i)) votes[i] = 0;
    }

    state = state.copyWith(
      askAudienceUsed: true,
      audienceVotes: votes,
    );
  }

  // Reset lifeline (after watching ad)
  void resetFiftyFifty() =>
      state = state.copyWith(fiftyFiftyUsed: false);
  void resetSkip() =>
      state = state.copyWith(skipUsed: false);
  void resetAskAudience() =>
      state = state.copyWith(askAudienceUsed: false);

  void timeUp() {
    if (state.selectedAnswers[state.currentIndex] != null) return;
    final newAnswers = List<int?>.from(state.selectedAnswers);
    newAnswers[state.currentIndex] = -2;
    state = state.copyWith(selectedAnswers: newAnswers);
  }

  void finishQuiz() => state = state.copyWith(isFinished: true);
}

final quizProvider =
    StateNotifierProvider.family<QuizNotifier, QuizState, List<QuestionModel>>(
  (ref, questions) => QuizNotifier(questions),
);