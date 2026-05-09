import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';
import '../data/categories_data.dart';
import '../models/category_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/stats_provider.dart';
import '../services/auth_service.dart';
import '../widgets/stat_card.dart';
import '../widgets/category_card.dart';
import '../widgets/daily_challenge_banner.dart';
import 'login_screen.dart';
import 'quiz_setup_screen.dart';
import 'leaderboard_screen.dart';
import 'multiplayer_lobby_screen.dart';
import '../main.dart';
import '../providers/category_provider.dart';


class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CategoryModel> get _filteredCategories {
    if (_searchQuery.isEmpty) return appCategories;
    return appCategories
        .where((c) => c.name
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()))
        .toList();
  }

  Future<void> _signOut() async {
    await ref.read(authServiceProvider).signOut();
    // Clear local user state
    ref.read(userModelProvider.notifier).state = null;
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use real-time stream instead of static provider
    final statsAsync = ref.watch(userStreamProvider);
    final dailyDone = ref.watch(dailyChallengeProvider);
    final countsAsync = ref.watch(categoryCountsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeTab(statsAsync, dailyDone, countsAsync),
          const LeaderboardScreen(),
          const MultiplayerLobbyScreen(),
          _buildProfileTab(statsAsync),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (i) => setState(() => _selectedIndex = i),
            backgroundColor: AppColors.cardBg,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textHint,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle: GoogleFonts.poppins(
                fontSize: 11, fontWeight: FontWeight.w600),
            unselectedLabelStyle:
                GoogleFonts.poppins(fontSize: 11),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.leaderboard_outlined),
                activeIcon: Icon(Icons.leaderboard_rounded),
                label: 'Leaderboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_outline_rounded),
                activeIcon: Icon(Icons.people_rounded),
                label: 'Multiplayer',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded),
                activeIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Home Tab ─────────────────────────────────────────────────────
  Widget _buildHomeTab(
      AsyncValue<UserModel?> statsAsync, bool dailyDone,
      AsyncValue<Map<String, int>> countsAsync,) {
    return CustomScrollView(
      slivers: [
        // ── App Bar ───────────────────────────────────────────────
        SliverAppBar(
          backgroundColor: AppColors.background,
          expandedHeight: 120,
          floating: true,
          pinned: true,
          elevation: 0,
          flexibleSpace: FlexibleSpaceBar(
            background: statsAsync.when(
              data: (user) => Padding(
                padding: const EdgeInsets.fromLTRB(24, 50, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Hello, ${user?.username ?? 'Player'} 👋',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Ready to quiz today?',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    // Live coin counter
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFFFFD700)
                                .withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Text('🪙',
                              style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 6),
                          Text(
                            '${user?.coins ?? 0}',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFFFD700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Daily Challenge ─────────────────────────────
                DailyChallengeBanner(
                  isCompleted: dailyDone,
                  onTap: () {
                    if (!dailyDone) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Daily Challenge starting...'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    }
                  },
                ),

                const SizedBox(height: 28),

                // ── Stats (real-time) ───────────────────────────
                Text(
                  'Your Stats',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),

                statsAsync.when(
                  data: (user) => GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.3,
                    children: [
                      StatCard(
                        label: 'Games Played',
                        value: '${user?.gamesPlayed ?? 0}',
                        icon: Icons.sports_esports_rounded,
                        color: AppColors.primary,
                      ),
                      StatCard(
                        label: 'Games Won',
                        value: '${user?.gamesWon ?? 0}',
                        icon: Icons.emoji_events_rounded,
                        color: const Color(0xFFFFD700),
                      ),
                      StatCard(
                        label: 'Total Score',
                        value: '${user?.totalScore ?? 0}',
                        icon: Icons.stars_rounded,
                        color: const Color(0xFF4CAF50),
                      ),
                      StatCard(
                        label: 'Level',
                        value: 'Lv. ${user?.level ?? 1}',
                        icon: Icons.trending_up_rounded,
                        color: const Color(0xFFFF9800),
                      ),
                    ],
                  ),
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(
                          color: AppColors.primary),
                    ),
                  ),
                  error: (_, __) => const SizedBox(),
                ),

                const SizedBox(height: 28),

                // ── Search ──────────────────────────────────────
                TextField(
                  controller: _searchController,
                  onChanged: (val) =>
                      setState(() => _searchQuery = val),
                  style: const TextStyle(
                      color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search categories...',
                    hintStyle: const TextStyle(
                        color: AppColors.textHint),
                    prefixIcon: const Icon(Icons.search,
                        color: AppColors.textHint),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close,
                                color: AppColors.textHint),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.cardBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 2),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Categories',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${_filteredCategories.length} topics',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
        ),

        // ── Categories Grid ────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          sliver: _filteredCategories.isEmpty
              ? SliverToBoxAdapter(
                  child: Center(
                    child: Column(
                      children: [
                        const Text('🔍',
                            style: TextStyle(fontSize: 50)),
                        const SizedBox(height: 12),
                        Text(
                          'No categories found',
                          style: GoogleFonts.poppins(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final category =
                          _filteredCategories[index];
                      final counts = countsAsync.value; // null while loading
                      return CategoryCard(
                        category: category,
                        questionCount: counts?[category.id], // null shows shimmer
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => QuizSetupScreen(category: category),
                          ),
                        ),
                      );
                    },
                    childCount: _filteredCategories.length,
                  ),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.85,
                  ),
                ),
        ),
      ],
    );
  }

  // ── Profile Tab (real-time) ───────────────────────────────────────
  Widget _buildProfileTab(AsyncValue<UserModel?> statsAsync) {
    return SafeArea(
      child: statsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, __) => Center(
          child: Text('Error loading profile',
              style: GoogleFonts.poppins(
                  color: AppColors.textSecondary)),
        ),
        data: (user) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Avatar
              Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primary,
                    backgroundImage: (user?.photoUrl ?? '').isNotEmpty
                        ? NetworkImage(user!.photoUrl)
                        : null,
                    child: (user?.photoUrl ?? '').isEmpty
                        ? Text(
                            (user?.username ?? 'P')[0]
                                .toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.background, width: 2),
                      ),
                      child: const Icon(Icons.edit,
                          color: Colors.white, size: 14),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Text(
                user?.username ?? 'Player',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              if ((user?.email ?? '').isNotEmpty)
                Text(
                  user!.email,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),

              const SizedBox(height: 8),

              // Level badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.5)),
                ),
                child: Text(
                  '⭐ Level ${user?.level ?? 1} Player',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // XP progress bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text('XP Progress',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: AppColors.textSecondary)),
                      Text(
                          '${user?.xp ?? 0} / ${((user?.level ?? 1)) * 500} XP',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: (((user?.xp ?? 0) % 500) / 500).clamp(0.0, 1.0),
                      backgroundColor: AppColors.cardBg,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary),
                      minHeight: 10,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Stats grid
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: [
                  _profileStat('🎮',
                      '${user?.gamesPlayed ?? 0}', 'Played'),
                  _profileStat(
                      '🏆', '${user?.gamesWon ?? 0}', 'Won'),
                  _profileStat(
                      '🪙', '${user?.coins ?? 0}', 'Coins'),
                ],
              ),

              const SizedBox(height: 24),

              // Accuracy card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceAround,
                  children: [
                    _miniStat('⭐',
                        '${user?.totalScore ?? 0}', 'Score'),
                    _divider(),
                    _miniStat(
                      '📊',
                      (user == null || user.gamesPlayed == 0)
                        ? '0%'
                        : '${((user.gamesWon / user.gamesPlayed) * 100).round()}%',
                      'Win Rate',
                    ),
                    _divider(),
                    _miniStat('🔥',
                        'Lv. ${user?.level ?? 1}', 'Level'),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Sign Out
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout_rounded,
                      color: AppColors.error),
                  label: Text(
                    'Sign Out',
                    style: GoogleFonts.poppins(
                      color: AppColors.error,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side:
                        const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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

  Widget _profileStat(String emoji, String value, String label) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
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
      ),
    );
  }

  Widget _miniStat(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _divider() => Container(
        height: 40, width: 1, color: AppColors.inputBg);
}