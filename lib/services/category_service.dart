import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../data/sample_questions.dart';

class CategoryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Check if device is online
  Future<bool> _isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  // Get question count for a single category
  // Online  → count from Firestore
  // Offline → count from local sample_questions.dart
  Future<int> getQuestionCount(String categoryId) async {
    try {
      if (await _isOnline()) {
        // Try Firestore first
        final snap = await _db
            .collection('questions')
            .where('category', isEqualTo: categoryId)
            .count()
            .get();
        final firestoreCount = snap.count ?? 0;

        // If Firestore has no questions yet, fall back to local
        if (firestoreCount > 0) return firestoreCount;
      }
    } catch (_) {
      // Firestore failed — fall back to local
    }

    // Offline or Firestore empty → use local sample count
    return sampleQuestions[categoryId]?.length ?? 0;
  }

  // Get counts for ALL categories at once (efficient batch)
  Future<Map<String, int>> getAllCategoryCounts() async {
    final Map<String, int> counts = {};

    try {
      if (await _isOnline()) {
        // Fetch all questions grouped by category in one query
        final snap = await _db
            .collection('questions')
            .get();

        // Group by category
        final Map<String, int> firestoreCounts = {};
        for (final doc in snap.docs) {
          final cat = doc.data()['category'] as String? ?? '';
          firestoreCounts[cat] = (firestoreCounts[cat] ?? 0) + 1;
        }

        // For each category, use Firestore count if available,
        // otherwise fall back to local
        for (final entry in sampleQuestions.entries) {
          final firestoreCount = firestoreCounts[entry.key] ?? 0;
          counts[entry.key] = firestoreCount > 0
              ? firestoreCount
              : entry.value.length;
        }

        // Also include any Firestore-only categories
        for (final entry in firestoreCounts.entries) {
          if (!counts.containsKey(entry.key)) {
            counts[entry.key] = entry.value;
          }
        }

        return counts;
      }
    } catch (_) {
      // Fall through to offline
    }

    // Offline — use all local counts
    for (final entry in sampleQuestions.entries) {
      counts[entry.key] = entry.value.length;
    }
    return counts;
  }

  // Stream that updates counts in real-time when Firestore changes
  Stream<Map<String, int>> streamCategoryCounts() async* {
    // Emit offline counts immediately
    final offlineCounts = <String, int>{};
    for (final entry in sampleQuestions.entries) {
      offlineCounts[entry.key] = entry.value.length;
    }
    yield offlineCounts;

    // Then stream live Firestore updates
    try {
      await for (final snap
          in _db.collection('questions').snapshots()) {
        final Map<String, int> counts = {};

        // Start with offline counts as baseline
        for (final entry in sampleQuestions.entries) {
          counts[entry.key] = entry.value.length;
        }

        // Count from Firestore
        final Map<String, int> firestoreCounts = {};
        for (final doc in snap.docs) {
          final cat = doc.data()['category'] as String? ?? '';
          firestoreCounts[cat] =
              (firestoreCounts[cat] ?? 0) + 1;
        }

        // Override with Firestore counts where available
        for (final entry in firestoreCounts.entries) {
          if (entry.value > 0) {
            counts[entry.key] = entry.value;
          }
        }

        yield counts;
      }
    } catch (_) {
      // Stream ended — already yielded offline counts
    }
  }
}