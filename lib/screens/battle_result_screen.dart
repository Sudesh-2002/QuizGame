import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';
import '../models/room_model.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';
import 'multiplayer_lobby_screen.dart';

class BattleResultScreen extends ConsumerWidget {
  final RoomModel room;

  const BattleResultScreen({super.key, required this.room});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userModelProvider);
    final myUid = user?.uid ?? '';
    final opponentUid =
        myUid == room.hostUid ? room.guestUid ?? '' : room.hostUid;
    final opponentName = myUid == room.hostUid
        ? room.guestUsername ?? 'Opponent'
        : room.hostUsername;

    final myScore = room.scores[myUid] ?? 0;
    final opponentScore = room.scores[opponentUid] ?? 0;

    final iWon = myScore > opponentScore;
    final isDraw = myScore == opponentScore;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 30),

              // Result emoji
              Text(
                isDraw ? '🤝' : iWon ? '🏆' : '😢',
                style: const TextStyle(fontSize: 80),
              ),

              const SizedBox(height: 16),

              Text(
                isDraw
                    ? "It's a Draw!"
                    : iWon
                        ? 'You Won!'
                        : 'You Lost!',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: isDraw
                      ? AppColors.warning
                      : iWon
                          ? const Color(0xFFFFD700)
                          : AppColors.error,
                ),
              ),

              Text(
                isDraw
                    ? 'Great match, well played!'
                    : iWon
                        ? 'Amazing performance!'
                        : 'Better luck next time!',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 36),

              // Score comparison
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    // My score
                    Expanded(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: iWon || isDraw
                                ? const Color(0xFFFFD700)
                                : AppColors.error,
                            child: Text(
                              (user?.username ?? 'You')[0]
                                  .toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            user?.username ?? 'You',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '$myScore pts',
                            style: GoogleFonts.poppins(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: iWon
                                  ? const Color(0xFFFFD700)
                                  : AppColors.textPrimary,
                            ),
                          ),
                          if (iWon)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD700)
                                    .withOpacity(0.2),
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                              child: Text(
                                '👑 Winner',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: const Color(0xFFFFD700),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // VS divider
                    Column(
                      children: [
                        const Text('⚔️',
                            style: TextStyle(fontSize: 28)),
                        Text(
                          'VS',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),

                    // Opponent score
                    Expanded(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: !iWon || isDraw
                                ? const Color(0xFFFFD700)
                                : AppColors.error,
                            child: Text(
                              opponentName[0].toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            opponentName,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '$opponentScore pts',
                            style: GoogleFonts.poppins(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: !iWon
                                  ? const Color(0xFFFFD700)
                                  : AppColors.textPrimary,
                            ),
                          ),
                          if (!iWon && !isDraw)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD700)
                                    .withOpacity(0.2),
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                              child: Text(
                                '👑 Winner',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: const Color(0xFFFFD700),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Stats row
              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      '🎯',
                      '${room.questionCount}',
                      'Questions',
                      AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statCard(
                      '⚡',
                      room.difficulty,
                      'Difficulty',
                      AppColors.warning,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Buttons
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const MultiplayerLobbyScreen(),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    '🔄  Play Again',
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
                  onPressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const HomeScreen()),
                    (r) => false,
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    '🏠  Back to Home',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: AppColors.primary,
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

  Widget _statCard(
      String emoji, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}