import 'package:cloud_firestore/cloud_firestore.dart';

class QuizService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Save quiz result to Firestore
  Future<void> saveQuizResult({
    required String uid,
    required String categoryId,
    required String difficulty,
    required int score,
    required int coinsEarned,
    required int correct,
    required int total,
  }) async {
    final batch = _db.batch();

    // Add to quiz_results collection
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

    // Update user stats
    final userRef = _db.collection('users').doc(uid);
    batch.update(userRef, {
      'totalScore': FieldValue.increment(score),
      'coins': FieldValue.increment(coinsEarned),
      'gamesPlayed': FieldValue.increment(1),
    });

    await batch.commit();
  }
}