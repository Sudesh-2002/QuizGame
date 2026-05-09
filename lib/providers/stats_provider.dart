import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'auth_provider.dart';

// Real-time stats — streams directly from Firestore
// Automatically updates whenever coins, score, level changes
final userStatsStreamProvider =
    StreamProvider.autoDispose<UserModel?>((ref) {
  final user = ref.watch(userModelProvider);
  if (user == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((snap) =>
          snap.exists ? UserModel.fromMap(snap.data()!) : null);
});

// Daily challenge completed flag
final dailyChallengeProvider = StateProvider<bool>((ref) => false);