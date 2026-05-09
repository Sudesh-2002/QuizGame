import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';
import '../data/categories_data.dart';
import '../models/category_model.dart';
import '../providers/auth_provider.dart';
import '../providers/multiplayer_provider.dart';
import '../services/multiplayer_service.dart';
import 'battle_screen.dart';
import 'battle_waiting_screen.dart';
import '../models/room_model.dart';

class MultiplayerLobbyScreen extends ConsumerStatefulWidget {
  const MultiplayerLobbyScreen({super.key});

  @override
  ConsumerState<MultiplayerLobbyScreen> createState() =>
      _MultiplayerLobbyScreenState();
}

class _MultiplayerLobbyScreenState
    extends ConsumerState<MultiplayerLobbyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _codeController = TextEditingController();
  CategoryModel _selectedCategory = appCategories.first;
  String _difficulty = 'Medium';
  int _questionCount = 10;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  // ── Create Room ─────────────────────────────────────────────────
  Future<void> _createRoom() async {
    final user = ref.read(userModelProvider);
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final room = await MultiplayerService().createRoom(
        hostUid: user.uid,
        hostUsername: user.username,
        categoryId: _selectedCategory.id,
        difficulty: _difficulty,
        questionCount: _questionCount,
      );

      ref.read(currentRoomProvider.notifier).state = room;

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BattleWaitingScreen(room: room),
          ),
        );
      }
    } catch (e) {
      _showError('Failed to create room: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Join Room ───────────────────────────────────────────────────
  Future<void> _joinRoom() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      _showError('Please enter a 6-digit room code');
      return;
    }

    final user = ref.read(userModelProvider);
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final room = await MultiplayerService().joinRoom(
        code: code,
        guestUid: user.uid,
        guestUsername: user.username,
      );

      if (room == null) {
        _showError('Room not found or already full');
        return;
      }

      ref.read(currentRoomProvider.notifier).state = room;

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BattleWaitingScreen(room: room),
          ),
        );
      }
    } catch (e) {
      _showError('Failed to join room: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Quick Match ─────────────────────────────────────────────────
  Future<void> _quickMatch() async {
    final user = ref.read(userModelProvider);
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      // Try to find open room
      RoomModel? room = await MultiplayerService().quickMatch(
        uid: user.uid,
        username: user.username,
        categoryId: _selectedCategory.id,
      );

      // No open room found → create one
      room ??= await MultiplayerService().createRoom(
        hostUid: user.uid,
        hostUsername: user.username,
        categoryId: _selectedCategory.id,
        difficulty: _difficulty,
        questionCount: _questionCount,
      );

      ref.read(currentRoomProvider.notifier).state = room;

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BattleWaitingScreen(room: room!),
          ),
        );
      }
    } catch (e) {
      _showError('Quick match failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        automaticallyImplyLeading: false,
        title: Text(
          '👥 Multiplayer',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textHint,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle: GoogleFonts.poppins(
                fontSize: 13, fontWeight: FontWeight.w600),
            unselectedLabelStyle: GoogleFonts.poppins(fontSize: 13),
            tabs: const [
              Tab(text: '⚡ Quick Match'),
              Tab(text: '🏠 Create'),
              Tab(text: '🔑 Join'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildQuickMatchTab(),
          _buildCreateTab(),
          _buildJoinTab(),
        ],
      ),
    );
  }

  // ── Quick Match Tab ─────────────────────────────────────────────
  Widget _buildQuickMatchTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // Hero banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF9D97FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text('⚔️', style: TextStyle(fontSize: 60)),
                const SizedBox(height: 12),
                Text(
                  '1v1 Battle',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Challenge a random player\nand prove your knowledge!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Category pick
          _sectionLabel('Pick Category'),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: appCategories.length,
              itemBuilder: (ctx, i) {
                final cat = appCategories[i];
                final sel = _selectedCategory.id == cat.id;
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedCategory = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 90,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: sel
                          ? cat.color.withOpacity(0.2)
                          : AppColors.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: sel ? cat.color : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(cat.emoji,
                            style: const TextStyle(fontSize: 28)),
                        const SizedBox(height: 6),
                        Text(
                          cat.name.split(' ').first,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: sel
                                ? cat.color
                                : AppColors.textSecondary,
                            fontWeight: sel
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 32),

          // Quick match button
          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _quickMatch,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 6,
                shadowColor: AppColors.primary.withOpacity(0.4),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(
                      color: Colors.white)
                  : Text(
                      '⚡  Find Match',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 24),

          // How it works
          _buildHowItWorks(),
        ],
      ),
    );
  }

  // ── Create Room Tab ─────────────────────────────────────────────
  Widget _buildCreateTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          _sectionLabel('Category'),
          const SizedBox(height: 12),

          // Category grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.1,
            ),
            itemCount: appCategories.length,
            itemBuilder: (ctx, i) {
              final cat = appCategories[i];
              final sel = _selectedCategory.id == cat.id;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: sel
                        ? cat.color.withOpacity(0.2)
                        : AppColors.cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: sel ? cat.color : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(cat.emoji,
                          style: const TextStyle(fontSize: 26)),
                      const SizedBox(height: 4),
                      Text(
                        cat.name.split(' ').first,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: sel
                              ? cat.color
                              : AppColors.textSecondary,
                          fontWeight: sel
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          _sectionLabel('Difficulty'),
          const SizedBox(height: 12),

          Row(
            children: ['Easy', 'Medium', 'Hard'].map((diff) {
              final sel = _difficulty == diff;
              final color = diff == 'Easy'
                  ? AppColors.success
                  : diff == 'Medium'
                      ? AppColors.warning
                      : AppColors.error;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _difficulty = diff),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: sel
                          ? color.withOpacity(0.15)
                          : AppColors.cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: sel ? color : Colors.transparent,
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
                          style: const TextStyle(fontSize: 22),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          diff,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: sel
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: sel
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

          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionLabel('Questions'),
              Text(
                '$_questionCount',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),

          Slider(
            value: _questionCount.toDouble(),
            min: 5,
            max: 20,
            divisions: 3,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.cardBg,
            onChanged: (v) =>
                setState(() => _questionCount = v.toInt()),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _createRoom,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(
                      color: Colors.white)
                  : Text(
                      '🏠  Create Room',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Join Room Tab ───────────────────────────────────────────────
  Widget _buildJoinTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 30),

          const Text('🔑', style: TextStyle(fontSize: 64)),

          const SizedBox(height: 16),

          Text(
            'Join a Room',
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          Text(
            'Enter the 6-digit code\nyour friend shared with you',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 40),

          // Code input
          TextField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              letterSpacing: 12,
            ),
            decoration: InputDecoration(
              hintText: '000000',
              hintStyle: GoogleFonts.poppins(
                fontSize: 32,
                color: AppColors.textHint,
                letterSpacing: 12,
              ),
              counterText: '',
              filled: true,
              fillColor: AppColors.cardBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                    color: AppColors.primary, width: 2),
              ),
            ),
          ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _joinRoom,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(
                      color: Colors.white)
                  : Text(
                      '🔑  Join Room',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      );

  Widget _buildHowItWorks() {
    final steps = [
      ('⚡', 'Instant matching with online players'),
      ('❓', 'Same questions for both players'),
      ('🏆', 'Fastest & most correct answers wins'),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How it works',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...steps.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Text(s.$1,
                        style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        s.$2,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}