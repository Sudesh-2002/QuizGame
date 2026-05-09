import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/room_model.dart';
import '../services/multiplayer_service.dart';

// Current room state
final currentRoomProvider = StateProvider<RoomModel?>((ref) => null);

// Room stream provider
final roomStreamProvider =
    StreamProvider.family<RoomModel?, String>((ref, roomId) {
  return MultiplayerService().streamRoom(roomId);
});

// Multiplayer service
final multiplayerServiceProvider =
    Provider<MultiplayerService>((ref) => MultiplayerService());