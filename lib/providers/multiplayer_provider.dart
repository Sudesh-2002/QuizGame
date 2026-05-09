import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/room_model.dart';
import '../services/multiplayer_service.dart';

// Current room (set when user creates or joins)
final currentRoomProvider =
    StateProvider<RoomModel?>((ref) => null);

// Real-time room stream — autoDispose so it closes when screen pops
final roomStreamProvider =
    StreamProvider.autoDispose.family<RoomModel?, String>(
        (ref, roomId) {
  return FirebaseFirestore.instance
      .collection('rooms')
      .doc(roomId)
      .snapshots()
      .map((snap) =>
          snap.exists ? RoomModel.fromMap(snap.data()!) : null);
});

// Multiplayer service
final multiplayerServiceProvider =
    Provider<MultiplayerService>((ref) => MultiplayerService());