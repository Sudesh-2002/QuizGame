import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/leaderboard_model.dart';
import '../services/leaderboard_service.dart';

// Tab index provider
final leaderboardTabProvider = StateProvider<int>((ref) => 0);

// Global leaderboard
final globalLeaderboardProvider =
    FutureProvider<List<LeaderboardEntry>>((ref) async {
  return LeaderboardService().getGlobalLeaderboard();
});

// Weekly leaderboard
final weeklyLeaderboardProvider =
    FutureProvider<List<LeaderboardEntry>>((ref) async {
  return LeaderboardService().getWeeklyLeaderboard();
});

// My rank
final myRankProvider = FutureProvider.family<int, String>((ref, uid) async {
  return LeaderboardService().getMyGlobalRank(uid);
});

// Category leaderboard
final categoryLeaderboardProvider =
    FutureProvider.family<List<LeaderboardEntry>, String>(
        (ref, categoryId) async {
  return LeaderboardService().getCategoryLeaderboard(categoryId);
});