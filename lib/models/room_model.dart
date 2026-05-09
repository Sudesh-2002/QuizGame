class RoomModel {
  final String roomId;
  final String roomCode;
  final String hostUid;
  final String hostUsername;
  final String? guestUid;
  final String? guestUsername;
  final String status; // waiting, playing, finished
  final String categoryId;
  final String difficulty;
  final int questionCount;
  final List<String> questionIds;
  final int currentQuestionIndex;
  final Map<String, int> scores;
  final Map<String, int?> currentAnswers;
  final Map<String, bool> ready;
  final DateTime createdAt;

  RoomModel({
    required this.roomId,
    required this.roomCode,
    required this.hostUid,
    required this.hostUsername,
    this.guestUid,
    this.guestUsername,
    this.status = 'waiting',
    required this.categoryId,
    required this.difficulty,
    required this.questionCount,
    this.questionIds = const [],
    this.currentQuestionIndex = 0,
    this.scores = const {},
    this.currentAnswers = const {},
    this.ready = const {},
    required this.createdAt,
  });

  bool get isFull => guestUid != null;
  bool get isWaiting => status == 'waiting';
  bool get isPlaying => status == 'playing';
  bool get isFinished => status == 'finished';

  factory RoomModel.fromMap(Map<String, dynamic> map) {
    return RoomModel(
      roomId: map['roomId'] ?? '',
      roomCode: map['roomCode'] ?? '',
      hostUid: map['hostUid'] ?? '',
      hostUsername: map['hostUsername'] ?? '',
      guestUid: map['guestUid'],
      guestUsername: map['guestUsername'],
      status: map['status'] ?? 'waiting',
      categoryId: map['categoryId'] ?? 'general',
      difficulty: map['difficulty'] ?? 'Medium',
      questionCount: map['questionCount'] ?? 10,
      questionIds: List<String>.from(map['questionIds'] ?? []),
      currentQuestionIndex: map['currentQuestionIndex'] ?? 0,
      scores: Map<String, int>.from(map['scores'] ?? {}),
      currentAnswers: Map<String, int?>.from(
        (map['currentAnswers'] ?? {}).map(
          (k, v) => MapEntry(k, v as int?),
        ),
      ),
      ready: Map<String, bool>.from(map['ready'] ?? {}),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'roomCode': roomCode,
      'hostUid': hostUid,
      'hostUsername': hostUsername,
      'guestUid': guestUid,
      'guestUsername': guestUsername,
      'status': status,
      'categoryId': categoryId,
      'difficulty': difficulty,
      'questionCount': questionCount,
      'questionIds': questionIds,
      'currentQuestionIndex': currentQuestionIndex,
      'scores': scores,
      'currentAnswers': currentAnswers,
      'ready': ready,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  RoomModel copyWith({
    String? guestUid,
    String? guestUsername,
    String? status,
    int? currentQuestionIndex,
    Map<String, int>? scores,
    Map<String, int?>? currentAnswers,
    Map<String, bool>? ready,
    List<String>? questionIds,
  }) {
    return RoomModel(
      roomId: roomId,
      roomCode: roomCode,
      hostUid: hostUid,
      hostUsername: hostUsername,
      guestUid: guestUid ?? this.guestUid,
      guestUsername: guestUsername ?? this.guestUsername,
      status: status ?? this.status,
      categoryId: categoryId,
      difficulty: difficulty,
      questionCount: questionCount,
      questionIds: questionIds ?? this.questionIds,
      currentQuestionIndex:
          currentQuestionIndex ?? this.currentQuestionIndex,
      scores: scores ?? this.scores,
      currentAnswers: currentAnswers ?? this.currentAnswers,
      ready: ready ?? this.ready,
      createdAt: createdAt,
    );
  }
}