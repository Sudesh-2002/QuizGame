import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';

class QuizTimer extends StatefulWidget {
  final int seconds;
  final VoidCallback onTimeUp;
  final bool isAnswered;

  const QuizTimer({
    super.key,
    required this.seconds,
    required this.onTimeUp,
    required this.isAnswered,
  });

  @override
  State<QuizTimer> createState() => _QuizTimerState();
}

class _QuizTimerState extends State<QuizTimer>
    with SingleTickerProviderStateMixin {
  late int _remaining;
  Timer? _timer;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _remaining = widget.seconds;
    _animController = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.seconds),
    )..forward();
    _startTimer();
  }

  @override
  void didUpdateWidget(QuizTimer old) {
    super.didUpdateWidget(old);
    // Reset when question changes
    if (old.seconds != widget.seconds || old.isAnswered != widget.isAnswered) {
      _timer?.cancel();
      _remaining = widget.seconds;
      _animController
        ..reset()
        ..forward();
      if (!widget.isAnswered) _startTimer();
    }
    // Stop timer if answered
    if (widget.isAnswered && !old.isAnswered) {
      _timer?.cancel();
      _animController.stop();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_remaining <= 1) {
        t.cancel();
        setState(() => _remaining = 0);
        widget.onTimeUp();
      } else {
        setState(() => _remaining--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  Color get _timerColor {
    if (_remaining > widget.seconds * 0.6) return AppColors.success;
    if (_remaining > widget.seconds * 0.3) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Timer circle
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: AnimatedBuilder(
                animation: _animController,
                builder: (_, __) => CircularProgressIndicator(
                  value: 1 - _animController.value,
                  strokeWidth: 5,
                  backgroundColor: AppColors.cardBg,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(_timerColor),
                ),
              ),
            ),
            Text(
              '$_remaining',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _timerColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}