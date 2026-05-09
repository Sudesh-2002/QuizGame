import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/question_model.dart';

class QuestionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<QuestionModel>> getQuestions({
    required String category,
    required String difficulty,
    required int count,
  }) async {
    try {
      print('🔍 Fetching questions: category=$category, difficulty=$difficulty, count=$count');

      Query query = _db
          .collection('questions')
          .where('category', isEqualTo: category);

      if (difficulty != 'All') {
        query = query.where('difficulty', isEqualTo: difficulty);
      }

      final snap = await query.get();

      print('📦 Firestore returned ${snap.docs.length} documents');

      if (snap.docs.isEmpty) {
        print('⚠️ No documents found in Firestore for this query');
        return [];
      }

      final questions = snap.docs.map((doc) {
        print('📄 Document: ${doc.id} → ${doc.data()}');
        return QuestionModel.fromMap(
          doc.data() as Map<String, dynamic>,
        );
      }).toList();

      questions.shuffle();
      return questions.take(count).toList();

    } catch (e) {
      print('❌ QuestionService error: $e');
      return [];
    }
  }
}