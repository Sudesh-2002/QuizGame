import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'auth_provider.dart';

final userStatsProvider = AsyncNotifierProvider<UserStatsNotifier, UserModel?>(() {
  return UserStatsNotifier();
});

class UserStatsNotifier extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async {
    final user = ref.watch(userModelProvider);
    if (user == null) return null;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) return UserModel.fromMap(doc.data()!);
    } catch (e) {
      print('Stats fetch error: $e');
    }
    return null;
  }
}

// Daily challenge completed provider
final dailyChallengeProvider = StateProvider<bool>((ref) => false);