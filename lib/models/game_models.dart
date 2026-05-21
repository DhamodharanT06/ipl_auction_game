// Enhanced data models for IPL Auction Multiplayer Game

class UserProfile {
  final String id;
  final String username;
  final String? avatarUrl;
  final int matchesPlayed;
  final int matchesWon;
  final int totalCoins;
  final List<String> badges;
  final bool soundEnabled;
  final bool darkModeEnabled;

  UserProfile({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.matchesPlayed = 0,
    this.matchesWon = 0,
    this.totalCoins = 0,
    this.badges = const [],
    this.soundEnabled = true,
    this.darkModeEnabled = false,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map, String id) {
    return UserProfile(
      id: id,
      username: map['username'] ?? '',
      avatarUrl: map['avatarUrl'],
      matchesPlayed: map['matchesPlayed'] ?? 0,
      matchesWon: map['matchesWon'] ?? 0,
      totalCoins: map['totalCoins'] ?? 0,
      badges: List<String>.from(map['badges'] ?? []),
      soundEnabled: map['soundEnabled'] ?? true,
      darkModeEnabled: map['darkModeEnabled'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'avatarUrl': avatarUrl ?? '',
      'matchesPlayed': matchesPlayed,
      'matchesWon': matchesWon,
      'totalCoins': totalCoins,
      'badges': badges,
      'soundEnabled': soundEnabled,
      'darkModeEnabled': darkModeEnabled,
    };
  }

  UserProfile copyWith({
    String? username,
    String? avatarUrl,
    int? matchesPlayed,
    int? matchesWon,
    int? totalCoins,
    List<String>? badges,
    bool? soundEnabled,
    bool? darkModeEnabled,
  }) {
    return UserProfile(
      id: id,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      matchesPlayed: matchesPlayed ?? this.matchesPlayed,
      matchesWon: matchesWon ?? this.matchesWon,
      totalCoins: totalCoins ?? this.totalCoins,
      badges: badges ?? this.badges,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
    );
  }
}

class Room {
  final String id;
  final String roomCode;
  final String hostId;
  final String hostName;
  final String status; // waiting, in_auction, completed
  final int playerCount;
  final int maxPlayers;
  final DateTime createdAt;

  Room({
    required this.id,
    required this.roomCode,
    required this.hostId,
    required this.hostName,
    required this.status,
    required this.playerCount,
    this.maxPlayers = 8,
    required this.createdAt,
  });

  factory Room.fromMap(Map<String, dynamic> map, String id) {
    return Room(
      id: id,
      roomCode: map['roomCode'] ?? '',
      hostId: map['hostId'] ?? '',
      hostName: map['hostName'] ?? '',
      status: map['status'] ?? 'waiting',
      playerCount: map['playerCount'] ?? 0,
      maxPlayers: map['maxPlayers'] ?? 8,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roomCode': roomCode,
      'hostId': hostId,
      'hostName': hostName,
      'status': status,
      'playerCount': playerCount,
      'maxPlayers': maxPlayers,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class RoomPlayer {
  final String id;
  final String roomId;
  final String userId;
  final String username;
  final String? avatarUrl;
  final bool isReady;
  final bool isHost;
  final String teamName;
  final int budget;
  final List<Map<String, dynamic>> playersOwned;
  final DateTime joinedAt;

  RoomPlayer({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.username,
    this.avatarUrl,
    this.isReady = false,
    this.isHost = false,
    this.teamName = '',
    this.budget = 10000,
    this.playersOwned = const [],
    required this.joinedAt,
  });

  factory RoomPlayer.fromMap(Map<String, dynamic> map, String id) {
    return RoomPlayer(
      id: id,
      roomId: map['roomId'] ?? '',
      userId: map['userId'] ?? '',
      username: map['username'] ?? '',
      avatarUrl: map['avatarUrl'],
      isReady: map['isReady'] ?? false,
      isHost: map['isHost'] ?? false,
      teamName: map['teamName'] ?? '',
      budget: map['budget'] ?? 10000,
      playersOwned: List<Map<String, dynamic>>.from(map['playersOwned'] ?? []),
      joinedAt: DateTime.parse(map['joinedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'userId': userId,
      'username': username,
      'avatarUrl': avatarUrl ?? '',
      'isReady': isReady,
      'isHost': isHost,
      'teamName': teamName,
      'budget': budget,
      'playersOwned': playersOwned,
      'joinedAt': joinedAt.toIso8601String(),
    };
  }

  RoomPlayer copyWith({
    String? teamName,
    bool? isReady,
    int? budget,
    List<Map<String, dynamic>>? playersOwned,
  }) {
    return RoomPlayer(
      id: id,
      roomId: roomId,
      userId: userId,
      username: username,
      avatarUrl: avatarUrl,
      isReady: isReady ?? this.isReady,
      isHost: isHost,
      teamName: teamName ?? this.teamName,
      budget: budget ?? this.budget,
      playersOwned: playersOwned ?? this.playersOwned,
      joinedAt: joinedAt,
    );
  }

  int get remainingBudget => budget;
  int get playersOwnedCount => playersOwned.length;
}

class Player {
  final String name;
  final String role;
  final int avgScore;
  final bool isForeign;
  final String? previousTeam;
  bool isSold;
  String? soldToTeam;
  int? soldPrice;

  Player({
    required this.name,
    required this.role,
    required this.avgScore,
    this.isForeign = false,
    this.previousTeam,
    this.isSold = false,
    this.soldToTeam,
    this.soldPrice,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'role': role,
      'avgScore': avgScore,
      'isForeign': isForeign,
      'previousTeam': previousTeam,
      'isSold': isSold,
      'soldToTeam': soldToTeam,
      'soldPrice': soldPrice,
    };
  }

  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      name: map['name'] ?? '',
      role: map['role'] ?? '',
      avgScore: map['avgScore'] ?? 0,
      isForeign: map['isForeign'] ?? false,
      previousTeam: map['previousTeam'],
      isSold: map['isSold'] ?? false,
      soldToTeam: map['soldToTeam'],
      soldPrice: map['soldPrice'],
    );
  }

  void markAsSold(String teamCode, int price) {
    isSold = true;
    soldToTeam = teamCode;
    soldPrice = price;
  }

  void markAsUnsold() {
    isSold = false;
    soldToTeam = null;
    soldPrice = null;
  }
}

class AuctionState {
  final String id;
  final String roomId;
  final int currentPlayerIndex;
  final List<Map<String, dynamic>> players;
  final int currentBid;
  final String currentBidder;
  final String currentBidderTeam;
  final String status; // active, paused, completed
  final int countdownPhase; // 0=normal, 1=going once, 2=going twice, 3=sold
  final DateTime startedAt;

  AuctionState({
    required this.id,
    required this.roomId,
    this.currentPlayerIndex = 0,
    required this.players,
    this.currentBid = 0,
    this.currentBidder = '',
    this.currentBidderTeam = '',
    this.status = 'active',
    this.countdownPhase = 0,
    required this.startedAt,
  });

  factory AuctionState.fromMap(Map<String, dynamic> map, String id) {
    return AuctionState(
      id: id,
      roomId: map['roomId'] ?? '',
      currentPlayerIndex: map['currentPlayerIndex'] ?? 0,
      players: List<Map<String, dynamic>>.from(map['players'] ?? []),
      currentBid: map['currentBid'] ?? 0,
      currentBidder: map['currentBidder'] ?? '',
      currentBidderTeam: map['currentBidderTeam'] ?? '',
      status: map['status'] ?? 'active',
      countdownPhase: map['countdownPhase'] ?? 0,
      startedAt: DateTime.parse(map['startedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'currentPlayerIndex': currentPlayerIndex,
      'players': players,
      'currentBid': currentBid,
      'currentBidder': currentBidder,
      'currentBidderTeam': currentBidderTeam,
      'status': status,
      'countdownPhase': countdownPhase,
      'startedAt': startedAt.toIso8601String(),
    };
  }

  Player get currentPlayer => Player.fromMap(players[currentPlayerIndex]);
  bool get hasMorePlayers => currentPlayerIndex < players.length - 1;

  int getNextBidIncrement(int currentBidAmount) {
    if (currentBidAmount == 0) return 10; // Start at 10L
    if (currentBidAmount < 500) return 10; // +10L for < 5Cr
    if (currentBidAmount < 1000) return 25; // +25L for 5-10Cr
    return 100; // +1Cr for > 10Cr
  }
}

class Bid {
  final String id;
  final String auctionId;
  final String userId;
  final String username;
  final int bidAmount;
  final String playerName;
  final DateTime timestamp;

  Bid({
    required this.id,
    required this.auctionId,
    required this.userId,
    required this.username,
    required this.bidAmount,
    required this.playerName,
    required this.timestamp,
  });

  factory Bid.fromMap(Map<String, dynamic> map, String id) {
    return Bid(
      id: id,
      auctionId: map['auctionId'] ?? '',
      userId: map['userId'] ?? '',
      username: map['username'] ?? '',
      bidAmount: map['bidAmount'] ?? 0,
      playerName: map['playerName'] ?? '',
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'auctionId': auctionId,
      'userId': userId,
      'username': username,
      'bidAmount': bidAmount,
      'playerName': playerName,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class TeamPlayer {
  final String name;
  final int cost;
  final bool isForeign;
  final String role;

  TeamPlayer({
    required this.name,
    required this.cost,
    this.isForeign = false,
    required this.role,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'cost': cost,
      'isForeign': isForeign,
      'role': role,
    };
  }

  factory TeamPlayer.fromMap(Map<String, dynamic> map) {
    return TeamPlayer(
      name: map['name'] ?? '',
      cost: map['cost'] ?? 0,
      isForeign: map['isForeign'] ?? false,
      role: map['role'] ?? '',
    );
  }
}
