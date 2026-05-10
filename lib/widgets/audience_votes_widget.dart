import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';

class AudienceVotesWidget extends StatefulWidget {
  final Map<int, int> votes;
  final List<String> options;
  final List<int> hiddenOptions;

  const AudienceVotesWidget({
    super.key,
    required this.votes,
    required this.options,
    required this.hiddenOptions,
  });

  @override
  State<AudienceVotesWidget> createState() => _AudienceVotesWidgetState();
}

class _AudienceVotesWidgetState extends State<AudienceVotesWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final labels = ['A', 'B', 'C', 'D'];
  final colors = [
    const Color(0xFF6C63FF),
    const Color(0xFF00BCD4),
    const Color(0xFF4CAF50),
    const Color(0xFFFF9800),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF9800).withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text('👥', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                'Ask the Audience',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFF9800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Vote bars
          ...List.generate(4, (i) {
            if (widget.hiddenOptions.contains(i)) {
              return const SizedBox();
            }
            final pct = widget.votes[i] ?? 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  // Label
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: colors[i].withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colors[i]),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      labels[i],
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colors[i],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Bar
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _animation,
                      builder: (_, __) => Stack(
                        children: [
                          // Background
                          Container(
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.inputBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          // Fill
                          FractionallySizedBox(
                            widthFactor: (pct / 100) * _animation.value,
                            child: Container(
                              height: 28,
                              decoration: BoxDecoration(
                                color: colors[i].withOpacity(0.7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          // Percentage text
                          Positioned.fill(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(
                                  '$pct%',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}