import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';
import '../models/leaderboard_model.dart';

class PodiumWidget extends StatelessWidget {
  final LeaderboardEntry first;
  final LeaderboardEntry? second;
  final LeaderboardEntry? third;

  const PodiumWidget({
    super.key,
    required this.first,
    this.second,
    this.third,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A1A2E),
            AppColors.primary.withOpacity(0.15),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── 2nd Place ──────────────────────────────────────────
          if (second != null)
            Expanded(
              child: _PodiumPlayer(
                entry: second!,
                height: 90,
                crownColor: const Color(0xFFC0C0C0),
                podiumColor: const Color(0xFF9E9E9E),
                medal: '🥈',
              ),
            ),

          const SizedBox(width: 8),

          // ── 1st Place ──────────────────────────────────────────
          Expanded(
            flex: 2,
            child: _PodiumPlayer(
              entry: first,
              height: 130,
              crownColor: const Color(0xFFFFD700),
              podiumColor: const Color(0xFFFFD700),
              medal: '👑',
              isFirst: true,
            ),
          ),

          const SizedBox(width: 8),

          // ── 3rd Place ──────────────────────────────────────────
          if (third != null)
            Expanded(
              child: _PodiumPlayer(
                entry: third!,
                height: 70,
                crownColor: const Color(0xFFCD7F32),
                podiumColor: const Color(0xFFCD7F32),
                medal: '🥉',
              ),
            ),
        ],
      ),
    );
  }
}

class _PodiumPlayer extends StatelessWidget {
  final LeaderboardEntry entry;
  final double height;
  final Color crownColor;
  final Color podiumColor;
  final String medal;
  final bool isFirst;

  const _PodiumPlayer({
    required this.entry,
    required this.height,
    required this.crownColor,
    required this.podiumColor,
    required this.medal,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Crown / Medal
        Text(medal, style: TextStyle(fontSize: isFirst ? 28 : 22)),

        const SizedBox(height: 6),

        // Avatar
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: crownColor, width: 3),
            boxShadow: [
              BoxShadow(
                color: crownColor.withOpacity(0.4),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: CircleAvatar(
            radius: isFirst ? 36 : 28,
            backgroundColor: AppColors.primary,
            backgroundImage: entry.photoUrl.isNotEmpty
                ? NetworkImage(entry.photoUrl)
                : null,
            child: entry.photoUrl.isEmpty
                ? Text(
                    entry.username[0].toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: isFirst ? 24 : 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
        ),

        const SizedBox(height: 8),

        // Username
        Text(
          entry.username,
          style: GoogleFonts.poppins(
            fontSize: isFirst ? 14 : 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),

        // Score
        Text(
          '${entry.totalScore} pts',
          style: GoogleFonts.poppins(
            fontSize: isFirst ? 13 : 11,
            color: crownColor,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 8),

        // Podium block
        Container(
          height: height,
          decoration: BoxDecoration(
            color: podiumColor.withOpacity(0.2),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(12),
            ),
            border: Border.all(color: podiumColor.withOpacity(0.5)),
          ),
          child: Center(
            child: Text(
              '#${entry.rank}',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: podiumColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}