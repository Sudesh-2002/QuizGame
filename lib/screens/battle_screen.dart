import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';
import '../data/sample_questions.dart';
import '../models/question_model.dart';
import '../models/room_model.dart';
import '../providers/auth_provider.dart';
import '../providers/multiplayer_provider.dart';
import '../services/multiplayer_service.dart';
import '../widgets/option_button.dart';
import 'battle_result_screen.dart';

class BattleScreen extends ConsumerStatefulWidget {
  final RoomModel room;

  const BattleScreen({super.key, required this.room});

  @override
  ConsumerState<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends ConsumerState<BattleScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnim;
  Timer? _timer;
  Timer? _advanceTimer;
  int _seconds = 20;
  bool _answered = false;
  bool _navigating = false;
  int? _myAnswer;
  List<QuestionModel> _questions = [];

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );
    _slideController.forward();

    // Load questions from sample data
    _questions = getQuestionsForCategory(
      widget.room.categoryId,
      widget.room.questionCount,
      widget.room.difficulty,
    );

    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _advanceTimer?.cancel();
    _slideController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _seconds = widget.room.difficulty == 'Easy'
        ? 30
        : widget.room.difficulty == 'Hard'
            ? 15
            : 20;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_seconds <= 1) {
        t.cancel();
        setState(() => _seconds = 0);
        if (!_answered) _onTimeUp();
      } else {
        setState(() => _seconds--);
      }
    });
  }

  void _onTimeUp() {
    setState(() {
      _answered = true;
      _myAnswer = -1;
    });
    _scheduleAdvance();
  }

  Future<void> _onAnswer(
      RoomModel room, QuestionModel question, int index) async {
    if (_answered) return;

    final user = ref.read(userModelProvider);
    final isCorrect = index == question.correctIndex;

    setState(() {
      _answered = true;
      _myAnswer = index;
    });

    _timer?.cancel();

    await MultiplayerService().submitAnswer(
      roomId: room.roomId,
      uid: user?.uid ?? '',
      answerIndex: index,
      isCorrect: isCorrect,
      difficulty: room.difficulty,
    );

    _scheduleAdvance();
  }

  // Advance after both answer or time up (host controls)
  void _scheduleAdvance() {
    _advanceTimer = Timer(const Duration(seconds: 2), () async {
      final user = ref.read(userModelProvider);
      if (user?.uid != widget.room.hostUid) return;

      final questions = _questions;
      final nextIndex = widget.room.currentQuestionIndex + 1;

      await MultiplayerService().advanceQuestion(
        widget.room.roomId,
        nextIndex,
        questions.length,
      );
    });
  }

  void _handleRoomUpdate(RoomModel? room) {
    if (room == null) return;

    if (room.isFinished && !_navigating) {
      _navigating = true;
      _timer?.cancel();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => BattleResultScreen(room: room),
          ),
        );
      });
      return;
    }

    // New question arrived
    if (room.currentQuestionIndex != widget.room.currentQuestionIndex) {
      setState(() {
        _answered = false;
        _myAnswer = null;
      });
      _startTimer();
      _slideController
        ..reset()
        ..forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userModelProvider);
    final roomStream =
        ref.watch(roomStreamProvider(widget.room.roomId));

    return roomStream.when(
      loading: () => _buildScaffold(
          const Center(child: CircularProgressIndicator(
              color: AppColors.primary))),
      error: (e, _) => _buildScaffold(
          Center(child: Text('Error: $e'))),
      data: (room) {
        if (room == null) return _buildScaffold(const SizedBox());

        _handleRoomUpdate(room);

        final qIndex = room.currentQuestionIndex;
        if (qIndex >= _questions.length) {
          return _buildScaffold(const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ));
        }

        final question = _questions[qIndex];
        final myUid = user?.uid ?? '';
        final opponentUid =
            myUid == room.hostUid ? room.guestUid : room.hostUid;
        final opponentName = myUid == room.hostUid
            ? room.guestUsername ?? 'Opponent'
            : room.hostUsername;
        final myScore = room.scores[myUid] ?? 0;
        final opponentScore = room.scores[opponentUid] ?? 0;
        final opponentAnswered =
            room.currentAnswers.containsKey(opponentUid);
        final labels = ['A', 'B', 'C', 'D'];

        return WillPopScope(
          onWillPop: () async => false,
          child: _buildScaffold(
            Column(
              children: [
                // ── Score Header ─────────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // My score
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.username ?? 'You',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '$myScore pts',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Timer + Progress
                      Column(
                        children: [
                          _timerCircle(),
                          const SizedBox(height: 4),
                          Text(
                            '${qIndex + 1}/${_questions.length}',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),

                      // Opponent score
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              opponentName,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.warning,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '$opponentScore pts',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Progress bar
                LinearProgressIndicator(
                  value: (qIndex + 1) / _questions.length,
                  backgroundColor: AppColors.inputBg,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary),
                  minHeight: 4,
                ),

                // ── Question & Options ───────────────────────────
                Expanded(
                  child: SlideTransition(
                    position: _slideAnim,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Opponent status indicator
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: opponentAnswered
                                  ? AppColors.success.withOpacity(0.1)
                                  : AppColors.cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: opponentAnswered
                                    ? AppColors.success.withOpacity(0.4)
                                    : AppColors.inputBg,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Text(
                                  opponentAnswered ? '✅' : '⏳',
                                  style:
                                      const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  opponentAnswered
                                      ? '$opponentName answered!'
                                      : '$opponentName is thinking...',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: opponentAnswered
                                        ? AppColors.success
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Question card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.primaryDark,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary
                                      .withOpacity(0.35),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Question ${qIndex + 1}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.white60,
                                  ),
                                ),
                                const SizedBox(height: 10),
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

                          // Options
                          ...question.options.asMap().entries.map(
                            (entry) {
                              final i = entry.key;
                              final text = entry.value;
                              final isSelected = _myAnswer == i;
                              final isCorrect =
                                  _answered &&
                                      i == question.correctIndex;
                              final isWrong = _answered &&
                                  isSelected &&
                                  i != question.correctIndex;

                              return OptionButton(
                                text: text,
                                label: labels[i],
                                isDisabled: _answered,
                                isSelected:
                                    isSelected && !_answered,
                                isCorrect: isCorrect,
                                isWrong: isWrong,
                                onTap: () => _onAnswer(
                                    room, question, i),
                              );
                            },
                          ),

                          if (_answered) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.cardBg,
                                borderRadius:
                                    BorderRadius.circular(14),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Waiting for next question...',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _timerCircle() {
    final maxSecs = widget.room.difficulty == 'Easy'
        ? 30
        : widget.room.difficulty == 'Hard'
            ? 15
            : 20;
    final color = _seconds > maxSecs * 0.6
        ? AppColors.success
        : _seconds > maxSecs * 0.3
            ? AppColors.warning
            : AppColors.error;

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 56,
          height: 56,
          child: CircularProgressIndicator(
            value: _seconds / maxSecs,
            strokeWidth: 4,
            backgroundColor: AppColors.cardBg,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        Text(
          '$_seconds',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildScaffold(Widget body) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: body),
    );
  }
}