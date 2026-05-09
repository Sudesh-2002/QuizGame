import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

// Auth service
final authServiceProvider =
    Provider<AuthService>((ref) => AuthService());

// Firebase auth state
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// Local user model state (set after login)
final userModelProvider = StateProvider<UserModel?>((ref) => null);

// REAL-TIME user stream from Firestore
// Use this everywhere in the app instead of userModelProvider
// for live-updating data (coins, score, level, etc.)
final userStreamProvider = StreamProvider<UserModel?>((ref) {
  final user = ref.watch(userModelProvider);
  if (user == null) return Stream.value(null);
  return ref.watch(authServiceProvider).streamUser(user.uid);
});