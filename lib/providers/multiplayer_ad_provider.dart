import 'package:flutter_riverpod/flutter_riverpod.dart';

// Tracks consecutive multiplayer battles
final multiplayerBattleCountProvider = StateProvider<int>((ref) => 0);

// Whether user needs to watch ad to continue multiplayer
final needsMultiplayerAdProvider = Provider<bool>((ref) {
  final count = ref.watch(multiplayerBattleCountProvider);
  return count > 0 && count % 5 == 0;
});