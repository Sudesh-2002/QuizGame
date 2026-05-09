import 'package:cloud_firestore/cloud_firestore.dart';

class QuizService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> saveQuizResult({
    required String uid,
    required String categoryId,
    required String difficulty,
    required int score,
    required int coinsEarned,
    required int correct,
    required int total,
  }) async {
    // XP earned based on difficulty
    final xpEarned = difficulty == 'Easy'
        ? 20
        : difficulty == 'Medium'
            ? 40
            : 60;

    // Read current user to calculate level
    final userDoc =
        await _db.collection('users').doc(uid).get();
    final currentXp = (userDoc.data()?['xp'] ?? 0) as int;
    final currentLevel =
        (userDoc.data()?['level'] ?? 1) as int;

    final newXp = currentXp + xpEarned;
    // Level up every 500 XP
    final newLevel = (newXp ~/ 500) + 1;
    final didLevelUp = newLevel > currentLevel;

    final batch = _db.batch();

    // Save quiz result
    final resultRef = _db.collection('quiz_results').doc();
    batch.set(resultRef, {
      'uid': uid,
      'categoryId': categoryId,
      'difficulty': difficulty,
      'score': score,
      'coinsEarned': coinsEarned,
      'correct': correct,
      'total': total,
      'accuracy': (correct / total * 100).round(),
      'playedAt': FieldValue.serverTimestamp(),
    });

    // Update user stats atomically
    batch.update(_db.collection('users').doc(uid), {
      'totalScore': FieldValue.increment(score),
      'coins': FieldValue.increment(coinsEarned),
      'gamesPlayed': FieldValue.increment(1),
      'xp': newXp,
      'level': newLevel,
      if (didLevelUp) 'leveledUp': true,
    });

    await batch.commit();
  }
}