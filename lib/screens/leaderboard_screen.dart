import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';
import '../data/categories_data.dart';
import '../models/leaderboard_model.dart';
import '../providers/auth_provider.dart';
import '../providers/leaderboard_provider.dart';
import '../widgets/leaderboard_row.dart';
import '../widgets/my_rank_banner.dart';
import '../widgets/podium_widget.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() =>
      _LeaderboardScreenState();
}

class _LeaderboardScreenState
    extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'general';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userModelProvider);

    return Scaffold(
      backgroundColor: AppColors.background,

      // ── Fixed App Bar — does NOT scroll away ──────────────────
      appBar: AppBar(
        backgroundColor: AppColors.background,
        automaticallyImplyLeading: false,
        elevation: 0,
        titleSpacing: 20,
        title: Text(
          '🏆 Leaderboard',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              ref.invalidate(globalLeaderboardProvider);
              ref.invalidate(weeklyLeaderboardProvider);
            },
            icon: const Icon(Icons.refresh_rounded,
                color: AppColors.textSecondary),
          ),
        ],

        // Tab bar pinned inside AppBar — never scrolls
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          labelStyle: GoogleFonts.poppins(
              fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle:
              GoogleFonts.poppins(fontSize: 13),
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: 'Global'),
            Tab(text: 'Weekly'),
            Tab(text: 'Category'),
          ],
        ),
      ),

      // ── Body — TabBarView fills remaining space ────────────────
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGlobalTab(user),
          _buildWeeklyTab(user),
          _buildCategoryTab(user),
        ],
      ),
    );
  }

  // ── Global Tab ──────────────────────────────────────────────────
  Widget _buildGlobalTab(user) {
    final leaderboardAsync = ref.watch(globalLeaderboardProvider);
    final myRankAsync = user != null
        ? ref.watch(myRankProvider(user.uid))
        : null;

    return leaderboardAsync.when(
      loading: () => _buildLoader(),
      error: (e, _) => _buildError('Failed to load leaderboard',
          () => ref.invalidate(globalLeaderboardProvider)),
      data: (entries) {
        if (entries.isEmpty) return _buildEmpty();
        return RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.cardBg,
          onRefresh: () async =>
              ref.invalidate(globalLeaderboardProvider),
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 30),
            itemCount: entries.length + 2, // +2 for podium & banner
            itemBuilder: (context, index) {
              // Podium
              if (index == 0) {
                return entries.length >= 3
                    ? PodiumWidget(
                        first: entries[0],
                        second: entries[1],
                        third: entries[2],
                      )
                    : const SizedBox();
              }

              // My rank banner
              if (index == 1) {
                return user != null
                    ? myRankAsync?.when(
                          data: (rank) => MyRankBanner(
                            rank: rank,
                            totalScore: user.totalScore,
                            username: user.username,
                          ),
                          loading: () => const SizedBox(),
                          error: (_, __) => const SizedBox(),
                        ) ??
                        const SizedBox()
                    : const SizedBox();
              }

              // Leaderboard rows
              final entry = entries[index - 2];
              final isMe = user?.uid == entry.uid;
              return LeaderboardRow(
                  entry: entry, isCurrentUser: isMe);
            },
          ),
        );
      },
    );
  }

  // ── Weekly Tab ──────────────────────────────────────────────────
  Widget _buildWeeklyTab(user) {
    final weeklyAsync = ref.watch(weeklyLeaderboardProvider);

    return weeklyAsync.when(
      loading: () => _buildLoader(),
      error: (e, _) => _buildError('Failed to load weekly board',
          () => ref.invalidate(weeklyLeaderboardProvider)),
      data: (entries) {
        if (entries.isEmpty) {
          return _buildEmpty(
            message:
                'No games played this week yet!\nBe the first! 🎮',
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.cardBg,
          onRefresh: () async =>
              ref.invalidate(weeklyLeaderboardProvider),
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 30),
            itemCount: entries.length + 2,
            itemBuilder: (context, index) {
              if (index == 0) return _buildWeeklyBanner();
              if (index == 1) {
                return entries.length >= 3
                    ? PodiumWidget(
                        first: entries[0],
                        second: entries[1],
                        third: entries[2],
                      )
                    : const SizedBox();
              }
              final entry = entries[index - 2];
              final isMe = user?.uid == entry.uid;
              return LeaderboardRow(
                  entry: entry, isCurrentUser: isMe);
            },
          ),
        );
      },
    );
  }

  // ── Category Tab ────────────────────────────────────────────────
  Widget _buildCategoryTab(user) {
    final categoryAsync =
        ref.watch(categoryLeaderboardProvider(_selectedCategory));

    return Column(
      children: [
        // Category chips
        SizedBox(
          height: 56,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            itemCount: appCategories.length,
            itemBuilder: (context, index) {
              final cat = appCategories[index];
              final selected = _selectedCategory == cat.id;
              return GestureDetector(
                onTap: () =>
                    setState(() => _selectedCategory = cat.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected
                        ? cat.color.withOpacity(0.2)
                        : AppColors.cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? cat.color
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(cat.emoji,
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(
                        cat.name.split(' ').first,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: selected
                              ? cat.color
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // List
        Expanded(
          child: categoryAsync.when(
            loading: () => _buildLoader(),
            error: (e, _) => _buildError(
              'Failed to load category board',
              () => ref.invalidate(
                  categoryLeaderboardProvider(_selectedCategory)),
            ),
            data: (entries) {
              if (entries.isEmpty) {
                return _buildEmpty(
                  message:
                      'No scores yet in this category.\nPlay to be #1! 🎯',
                );
              }
              return RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.cardBg,
                onRefresh: () async => ref.invalidate(
                    categoryLeaderboardProvider(_selectedCategory)),
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 30),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final isMe = user?.uid == entry.uid;
                    return LeaderboardRow(
                        entry: entry, isCurrentUser: isMe);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Weekly Banner ───────────────────────────────────────────────
  Widget _buildWeeklyBanner() {
    final now = DateTime.now();
    final daysLeft = 7 - now.weekday;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF9800), Color(0xFFF44336)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9800).withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 40)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weekly Challenge',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Resets in $daysLeft day${daysLeft == 1 ? '' : 's'}  •  Top 3 win rewards',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoader() => const Center(
        child:
            CircularProgressIndicator(color: AppColors.primary),
      );

  Widget _buildError(String message, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('😕', style: TextStyle(fontSize: 50)),
          const SizedBox(height: 12),
          Text(message,
              style: GoogleFonts.poppins(
                  color: AppColors.textSecondary, fontSize: 15)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary),
            child: Text('Retry',
                style:
                    GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty({String message = 'No players yet!'}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🏆', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}