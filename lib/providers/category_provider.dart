import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/category_service.dart';

// Streams live question counts for all categories
// Immediately emits offline counts, then updates with Firestore
final categoryCountsProvider =
    StreamProvider<Map<String, int>>((ref) {
  return CategoryService().streamCategoryCounts();
});