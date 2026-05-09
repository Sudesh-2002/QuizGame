import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';
import '../models/room_model.dart';
import '../providers/auth_provider.dart';
import '../providers/multiplayer_provider.dart';
import '../services/multiplayer_service.dart';
import 'battle_screen.dart';

class BattleWaitingScreen extends ConsumerStatefulWidget {
  final RoomModel room;

  const BattleWaitingScreen({super.key, required this.room});

  @override
  ConsumerState<BattleWaitingScreen> createState() =>
      _BattleWaitingScreenState();
}

class _BattleWaitingScreenState
    extends ConsumerState<BattleWaitingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05)
        .animate(_pulseController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userModelProvider);
    final roomStream =
        ref.watch(roomStreamProvider(widget.room.roomId));

    return roomStream.when(
      loading: () => _buildScaffold(_buildLoader()),
      error: (e, _) => _buildScaffold(_buildError()),
      data: (room) {
        if (room == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.pop(context);
          });
          return _buildScaffold(_buildLoader());
        }

        // Auto-start when both ready
        if (room.isPlaying && !_navigating) {
          _navigating = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => BattleScreen(room: room),
              ),
            );
          });
        }

        final isHost = user?.uid == room.hostUid;
        final bothJoined = room.isFull;
        final myReady = room.ready[user?.uid] ?? false;
        final bothReady = room.ready.values
            .where((v) => v)
            .length ==
            2;

        return WillPopScope(
          onWillPop: () async {
            await MultiplayerService().leaveRoom(
              room.roomId,
              user?.uid ?? '',
              isHost,
            );
            return true;
          },
          child: _buildScaffold(
            SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  Text(
                    'Waiting Room',
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Room code
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(
                          ClipboardData(text: room.roomCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Room code copied!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.primary.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Code: ',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            room.roomCode,
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              letterSpacing: 6,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.copy_rounded,
                              color: AppColors.primary, size: 18),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Players VS display
                  Row(
                    children: [
                      Expanded(
                          child: _playerCard(
                        room.hostUsername,
                        '👑 Host',
                        room.ready[room.hostUid] ?? false,
                        AppColors.primary,
                      )),
                      Column(
                        children: [
                          const Text('⚔️',
                              style: TextStyle(fontSize: 30)),
                          Text(
                            'VS',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: bothJoined
                            ? _playerCard(
                                room.guestUsername ?? '',
                                '👤 Guest',
                                room.ready[room.guestUid] ?? false,
                                AppColors.warning,
                              )
                            : _waitingCard(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Game info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _infoItem('📚',
                            '${room.questionCount}', 'Questions'),
                        _infoItem('⚡', room.difficulty, 'Difficulty'),
                        _infoItem('🎯', room.categoryId, 'Category'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Ready button
                  if (bothJoined) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () async {
                          await MultiplayerService().setReady(
                            room.roomId,
                            user?.uid ?? '',
                            !myReady,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: myReady
                              ? AppColors.success
                              : AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          myReady ? '✅  Ready!' : 'Mark as Ready',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Host starts game when both ready
                    if (isHost && bothReady)
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () async {
                            await MultiplayerService()
                                .startGame(room.roomId);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFD700),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            '🚀  Start Battle!',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),

                    if (!bothReady)
                      Text(
                        'Waiting for both players to be ready...',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                  ] else
                    // Pulse animation while waiting
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppColors.primary.withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(
                              color: AppColors.primary,
                              strokeWidth: 3,
                            ),
                            const SizedBox(width: 14),
                            Text(
                              'Waiting for opponent...',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Leave button
                  TextButton(
                    onPressed: () async {
                      await MultiplayerService().leaveRoom(
                        room.roomId,
                        user?.uid ?? '',
                        isHost,
                      );
                      if (mounted) Navigator.pop(context);
                    },
                    child: Text(
                      'Leave Room',
                      style: GoogleFonts.poppins(
                        color: AppColors.error,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildScaffold(Widget body) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: body),
    );
  }

  Widget _playerCard(
      String name, String role, bool ready, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            role,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: ready
                  ? AppColors.success.withOpacity(0.2)
                  : AppColors.cardBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              ready ? '✅ Ready' : '⏳ Waiting',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: ready
                    ? AppColors.success
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _waitingCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textHint.withOpacity(0.3),
            style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.inputBg,
            child: const Icon(Icons.person_add_rounded,
                color: AppColors.textHint, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            'Waiting...',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textHint,
            ),
          ),
          Text(
            'Share code',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoItem(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildLoader() => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );

  Widget _buildError() => Center(
        child: Text(
          'Connection lost',
          style: GoogleFonts.poppins(color: AppColors.textSecondary),
        ),
      );
}