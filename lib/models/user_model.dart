class UserModel {
  final String uid;
  final String username;
  final String email;
  final String photoUrl;
  final int totalScore;
  final int gamesPlayed;
  final int gamesWon;
  final int coins;
  final int level;
  final int xp;
  final String country;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.username,
    required this.email,
    this.photoUrl = '',
    this.totalScore = 0,
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    this.coins = 100,
    this.level = 1,
    this.xp = 0,
    this.country = '',
    required this.createdAt,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'email': email,
      'photoUrl': photoUrl,
      'totalScore': totalScore,
      'gamesPlayed': gamesPlayed,
      'gamesWon': gamesWon,
      'coins': coins,
      'level': level,
      'xp': xp,
      'country': country,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create from Firestore Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      totalScore: map['totalScore'] ?? 0,
      gamesPlayed: map['gamesPlayed'] ?? 0,
      gamesWon: map['gamesWon'] ?? 0,
      coins: map['coins'] ?? 100,
      level: map['level'] ?? 1,
      xp: map['xp'] ?? 0,
      country: map['country'] ?? '',
      createdAt: DateTime.parse(
        map['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}