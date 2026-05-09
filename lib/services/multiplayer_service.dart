import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/sample_questions.dart';
import '../models/room_model.dart';

class MultiplayerService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Generate 6-digit room code ─────────────────────────────────
  String _generateCode() {
    final rand = Random();
    return List.generate(6, (_) => rand.nextInt(10)).join();
  }

  // ── Create Room ────────────────────────────────────────────────
  Future<RoomModel> createRoom({
    required String hostUid,
    required String hostUsername,
    required String categoryId,
    required String difficulty,
    required int questionCount,
  }) async {
    final code = _generateCode();
    final ref = _db.collection('rooms').doc();

    // Store question IDs using seeded shuffle with roomId as seed
    // Both host and guest will call getQuestionsForRoom(roomId)
    // and get identical question lists
    final questions = getQuestionsForRoom(
      categoryId,
      questionCount,
      difficulty,
      ref.id, // roomId is the seed
    );
    final questionIds = questions.map((q) => q.id).toList();

    final room = RoomModel(
      roomId: ref.id,
      roomCode: code,
      hostUid: hostUid,
      hostUsername: hostUsername,
      categoryId: categoryId,
      difficulty: difficulty,
      questionCount: questionCount,
      questionIds: questionIds,
      scores: {hostUid: 0},
      currentAnswers: {},
      ready: {hostUid: false},
      createdAt: DateTime.now(),
    );

    await ref.set(room.toMap());
    return room;
  }

  // ── Join Room by Code ──────────────────────────────────────────
  Future<RoomModel?> joinRoom({
    required String code,
    required String guestUid,
    required String guestUsername,
  }) async {
    final snap = await _db
        .collection('rooms')
        .where('roomCode', isEqualTo: code)
        .where('status', isEqualTo: 'waiting')
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;

    final doc = snap.docs.first;
    final room = RoomModel.fromMap(doc.data());

    if (room.isFull) return null;
    if (room.hostUid == guestUid) return null;

    // Update room with guest info
    await doc.reference.update({
      'guestUid': guestUid,
      'guestUsername': guestUsername,
      'scores': {...room.scores, guestUid: 0},
      'ready': {...room.ready, guestUid: false},
    });

    return room.copyWith(
      guestUid: guestUid,
      guestUsername: guestUsername,
    );
  }

  // ── Quick Match (auto-join open room) ──────────────────────────
  Future<RoomModel?> quickMatch({
    required String uid,
    required String username,
    required String categoryId,
  }) async {
    final snap = await _db
        .collection('rooms')
        .where('status', isEqualTo: 'waiting')
        .where('categoryId', isEqualTo: categoryId)
        .where('guestUid', isNull: true)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      final doc = snap.docs.first;
      final room = RoomModel.fromMap(doc.data());
      if (room.hostUid == uid) return null;

      await doc.reference.update({
        'guestUid': uid,
        'guestUsername': username,
        'scores': {...room.scores, uid: 0},
        'ready': {...room.ready, uid: false},
      });

      return RoomModel.fromMap({...doc.data(), 'guestUid': uid});
    }

    return null;
  }

  // ── Set Ready ──────────────────────────────────────────────────
  Future<void> setReady(String roomId, String uid, bool ready) async {
    await _db.collection('rooms').doc(roomId).update({
      'ready.$uid': ready,
    });
  }

  // ── Start Game (host only) ─────────────────────────────────────
  Future<void> startGame(String roomId) async {
    await _db.collection('rooms').doc(roomId).update({
      'status': 'playing',
      'currentQuestionIndex': 0,
    });
  }

  // ── Submit Answer ──────────────────────────────────────────────
  Future<void> submitAnswer({
    required String roomId,
    required String uid,
    required int answerIndex,
    required bool isCorrect,
    required String difficulty,
  }) async {
    final points = isCorrect
        ? (difficulty == 'Easy'
            ? 100
            : difficulty == 'Medium'
                ? 150
                : 200)
        : 0;

    await _db.collection('rooms').doc(roomId).update({
      'currentAnswers.$uid': answerIndex,
      if (isCorrect) 'scores.$uid': FieldValue.increment(points),
    });
  }

  // ── Advance Question ───────────────────────────────────────────
  Future<void> advanceQuestion(
      String roomId, int nextIndex, int totalQuestions) async {
    if (nextIndex >= totalQuestions) {
      await _db.collection('rooms').doc(roomId).update({
        'status': 'finished',
      });
    } else {
      await _db.collection('rooms').doc(roomId).update({
        'currentQuestionIndex': nextIndex,
        'currentAnswers': {},
      });
    }
  }

  // ── Leave / Delete Room ────────────────────────────────────────
  Future<void> leaveRoom(String roomId, String uid, bool isHost) async {
    if (isHost) {
      await _db.collection('rooms').doc(roomId).delete();
    } else {
      await _db.collection('rooms').doc(roomId).update({
        'guestUid': null,
        'guestUsername': null,
        'status': 'waiting',
      });
    }
  }

  // ── Stream Room ────────────────────────────────────────────────
  Stream<RoomModel?> streamRoom(String roomId) {
    return _db
        .collection('rooms')
        .doc(roomId)
        .snapshots()
        .map((snap) =>
            snap.exists ? RoomModel.fromMap(snap.data()!) : null);
  }

  // ── Clean old rooms (optional util) ───────────────────────────
  Future<void> cleanOldRooms() async {
    final cutoff =
        DateTime.now().subtract(const Duration(hours: 2));
    final snap = await _db
        .collection('rooms')
        .where('createdAt', isLessThan: cutoff.toIso8601String())
        .get();
    for (final doc in snap.docs) {
      await doc.reference.delete();
    }
  }
}