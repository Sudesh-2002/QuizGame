import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

// Auth service
final authServiceProvider =
    Provider<AuthService>((ref) => AuthService());

// Firebase auth state stream
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// Local user model — set after login or on app restore
final userModelProvider =
    StateProvider<UserModel?>((ref) => null);

// ONE-TIME fetch from Firestore (used by AuthGate on app restore)
final firestoreUserProvider =
    FutureProvider.family<UserModel?, String>((ref, uid) async {
  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .get();
  if (!doc.exists) return null;
  return UserModel.fromMap(doc.data()!);
});

// REAL-TIME stream of current user from Firestore
// Use this everywhere for live-updating UI
final userStreamProvider = StreamProvider<UserModel?>((ref) {
  final user = ref.watch(userModelProvider);
  if (user == null) return Stream.value(null);
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((snap) =>
          snap.exists ? UserModel.fromMap(snap.data()!) : null);
});