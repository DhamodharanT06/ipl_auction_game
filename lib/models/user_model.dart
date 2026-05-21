class UserModel {
  const UserModel({
    required this.userId,
    required this.username,
    required this.email,
    this.avatarUrl,
    this.matchesPlayed = 0,
    this.matchesWon = 0,
    this.totalCoins = 0,
    this.soundEnabled = true,
    this.darkModeEnabled = false,
    this.createdAt,
  });

  final String userId;
  final String username;
  final String email;
  final String? avatarUrl;
  final int matchesPlayed;
  final int matchesWon;
  final int totalCoins;
  final bool soundEnabled;
  final bool darkModeEnabled;
  final DateTime? createdAt;

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      userId: map['\$id'] as String? ?? map['userId'] as String,
      username: (map['username'] ?? 'Guest') as String,
      email: (map['email'] ?? '') as String,
      avatarUrl: map['avatarUrl'] as String?,
      matchesPlayed: (map['matchesPlayed'] ?? 0) as int,
      matchesWon: (map['matchesWon'] ?? 0) as int,
      totalCoins: (map['totalCoins'] ?? 0) as int,
      soundEnabled: (map['soundEnabled'] ?? true) as bool,
      darkModeEnabled: (map['darkModeEnabled'] ?? false) as bool,
      createdAt: map['createdAt'] != null 
          ? DateTime.tryParse(map['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      'avatarUrl': avatarUrl,
      'matchesPlayed': matchesPlayed,
      'matchesWon': matchesWon,
      'totalCoins': totalCoins,
      'soundEnabled': soundEnabled,
      'darkModeEnabled': darkModeEnabled,
    };
  }

  UserModel copyWith({
    String? username,
    String? email,
    String? avatarUrl,
    int? matchesPlayed,
    int? matchesWon,
    int? totalCoins,
    bool? soundEnabled,
    bool? darkModeEnabled,
    DateTime? createdAt,
  }) {
    return UserModel(
      userId: userId,
      username: username ?? this.username,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      matchesPlayed: matchesPlayed ?? this.matchesPlayed,
      matchesWon: matchesWon ?? this.matchesWon,
      totalCoins: totalCoins ?? this.totalCoins,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
