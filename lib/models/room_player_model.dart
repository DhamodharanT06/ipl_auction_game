class RoomPlayerModel {
  const RoomPlayerModel({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.username,
    this.teamName,
    this.budget = 80,
    this.isHost = false,
    this.isReady = false,
    this.teamConfirmed = false,
    this.joinedAt,
    this.updatedAt,
  });

  final String id;
  final String roomId;
  final String userId;
  final String username;
  final String? teamName;
  final int budget;
  final bool isHost;
  final bool isReady;
  final bool teamConfirmed;
  final DateTime? joinedAt;
  final DateTime? updatedAt;

  factory RoomPlayerModel.fromMap(Map<String, dynamic> map) {
    return RoomPlayerModel(
      id: map['\$id'] as String? ?? map['id'] as String,
      roomId: (map['roomId'] ?? '') as String,
      userId: (map['userId'] ?? '') as String,
      username: (map['username'] ?? '') as String,
      teamName: map['teamName'] as String?,
      budget: ((map['budget'] ?? 1000) as num).toInt(),
      isHost: (map['isHost'] ?? false) as bool,
      isReady: (map['isReady'] ?? false) as bool,
      teamConfirmed: (map['teamConfirmed'] ?? false) as bool,
      joinedAt: map['joinedAt'] != null
          ? DateTime.tryParse(map['joinedAt'].toString())
          : null,
      updatedAt: map['\$updatedAt'] != null
          ? DateTime.tryParse(map['\$updatedAt'].toString())
          : (map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt'].toString()) : null),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'userId': userId,
      'username': username,
      'teamName': teamName,
      'budget': budget,
      'isHost': isHost,
      'isReady': isReady,
      'teamConfirmed': teamConfirmed,
      'joinedAt': joinedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  RoomPlayerModel copyWith({
    String? teamName,
    int? budget,
    bool? isReady,
    bool? teamConfirmed,
    DateTime? updatedAt,
  }) {
    return RoomPlayerModel(
      id: id,
      roomId: roomId,
      userId: userId,
      username: username,
      teamName: teamName ?? this.teamName,
      budget: budget ?? this.budget,
      isHost: isHost,
      isReady: isReady ?? this.isReady,
      teamConfirmed: teamConfirmed ?? this.teamConfirmed,
      joinedAt: joinedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
