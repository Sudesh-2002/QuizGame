class LeaderboardEntry {
  final String uid;
  final String username;
  final String photoUrl;
  final int totalScore;
  final int gamesPlayed;
  final int gamesWon;
  final int level;
  final String country;
  final int rank;

  LeaderboardEntry({
    required this.uid,
    required this.username,
    required this.photoUrl,
    required this.totalScore,
    required this.gamesPlayed,
    required this.gamesWon,
    required this.level,
    required this.country,
    required this.rank,
  });

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map, int rank) {
    return LeaderboardEntry(
      uid: map['uid'] ?? '',
      username: map['username'] ?? 'Player',
      photoUrl: map['photoUrl'] ?? '',
      totalScore: map['totalScore'] ?? 0,
      gamesPlayed: map['gamesPlayed'] ?? 0,
      gamesWon: map['gamesWon'] ?? 0,
      level: map['level'] ?? 1,
      country: map['country'] ?? '',
      rank: rank,
    );
  }

  double get winRate =>
      gamesPlayed == 0 ? 0 : (gamesWon / gamesPlayed * 100);
}