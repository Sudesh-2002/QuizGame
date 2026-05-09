import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

// Auth Service Provider
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// Firebase Auth State Provider
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// Current User Model Provider
final userModelProvider = StateProvider<UserModel?>((ref) => null);