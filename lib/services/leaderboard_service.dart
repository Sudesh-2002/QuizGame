import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/leaderboard_model.dart';

class LeaderboardService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Global Top 50 ─────────────────────────────────────────────
  Future<List<LeaderboardEntry>> getGlobalLeaderboard() async {
    final snap = await _db
        .collection('users')
        .orderBy('totalScore', descending: true)
        .limit(50)
        .get();

    return snap.docs.asMap().entries.map((e) {
      return LeaderboardEntry.fromMap(e.value.data(), e.key + 1);
    }).toList();
  }

  // ── Weekly Top 50 ─────────────────────────────────────────────
  Future<List<LeaderboardEntry>> getWeeklyLeaderboard() async {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));

    final snap = await _db
        .collection('quiz_results')
        .where('playedAt', isGreaterThan: weekAgo)
        .get();

    // Aggregate scores by uid
    final Map<String, Map<String, dynamic>> scores = {};
    for (final doc in snap.docs) {
      final data = doc.data();
      final uid = data['uid'] as String;
      if (!scores.containsKey(uid)) {
        scores[uid] = {'uid': uid, 'totalScore': 0, 'gamesPlayed': 0};
      }
      scores[uid]!['totalScore'] += data['score'] ?? 0;
      scores[uid]!['gamesPlayed'] += 1;
    }

    // Fetch usernames
    final List<LeaderboardEntry> entries = [];
    int rank = 1;
    final sorted = scores.values.toList()
      ..sort((a, b) =>
          (b['totalScore'] as int).compareTo(a['totalScore'] as int));

    for (final s in sorted.take(50)) {
      final userDoc =
          await _db.collection('users').doc(s['uid']).get();
      if (userDoc.exists) {
        final data = {
          ...userDoc.data()!,
          'totalScore': s['totalScore'],
          'gamesPlayed': s['gamesPlayed'],
        };
        entries.add(LeaderboardEntry.fromMap(data, rank++));
      }
    }

    return entries;
  }

  // ── My Rank in Global ─────────────────────────────────────────
  Future<int> getMyGlobalRank(String uid) async {
    final myDoc = await _db.collection('users').doc(uid).get();
    if (!myDoc.exists) return 0;

    final myScore = myDoc.data()!['totalScore'] ?? 0;

    final snap = await _db
        .collection('users')
        .where('totalScore', isGreaterThan: myScore)
        .get();

    return snap.docs.length + 1;
  }

  // ── Category Leaderboard ──────────────────────────────────────
  Future<List<LeaderboardEntry>> getCategoryLeaderboard(
      String categoryId) async {
    final snap = await _db
        .collection('quiz_results')
        .where('categoryId', isEqualTo: categoryId)
        .orderBy('score', descending: true)
        .limit(50)
        .get();

    final Map<String, int> bestScores = {};
    for (final doc in snap.docs) {
      final data = doc.data();
      final uid = data['uid'] as String;
      final score = data['score'] as int;
      if (!bestScores.containsKey(uid) || bestScores[uid]! < score) {
        bestScores[uid] = score;
      }
    }

    final sorted = bestScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final List<LeaderboardEntry> entries = [];
    int rank = 1;
    for (final entry in sorted.take(20)) {
      final userDoc =
          await _db.collection('users').doc(entry.key).get();
      if (userDoc.exists) {
        final data = {
          ...userDoc.data()!,
          'totalScore': entry.value,
        };
        entries.add(LeaderboardEntry.fromMap(data, rank++));
      }
    }
    return entries;
  }
}