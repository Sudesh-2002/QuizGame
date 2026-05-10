import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/leaderboard_model.dart';
import '../services/leaderboard_service.dart';

final leaderboardTabProvider =
    StateProvider<int>((ref) => 0);

// autoDispose — refetches fresh data every time screen opens
final globalLeaderboardProvider =
    FutureProvider.autoDispose<List<LeaderboardEntry>>((ref) {
  return LeaderboardService().getGlobalLeaderboard();
});

final weeklyLeaderboardProvider =
    FutureProvider.autoDispose<List<LeaderboardEntry>>((ref) {
  return LeaderboardService().getWeeklyLeaderboard();
});

final myRankProvider =
    FutureProvider.autoDispose.family<int, String>((ref, uid) {
  return LeaderboardService().getMyGlobalRank(uid);
});

final categoryLeaderboardProvider =
    FutureProvider.autoDispose.family<List<LeaderboardEntry>,
        String>((ref, categoryId) {
  return LeaderboardService()
      .getCategoryLeaderboard(categoryId);
});