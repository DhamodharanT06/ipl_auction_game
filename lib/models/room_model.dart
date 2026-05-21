enum RoomStatus { waiting, inAuction, completed }

class RoomModel {
  const RoomModel({
    required this.roomId,
    required this.roomCode,
    required this.hostId,
    required this.hostName,
    this.status = RoomStatus.waiting,
    this.playerCount = 0,
    this.maxPlayers = 8,
    this.createdAt,
    this.participants = const [],
    this.currentPlayer,
    this.currentOrder = const [],
    this.highestBid = 0,
    this.auctionState,
    this.timer = 0,
    this.hostMode,
    this.allReadyForResult = false,
    this.updatedAt,
  });

  final String roomId;
  final String roomCode;
  final String hostId;
  final String hostName;
  final RoomStatus status;
  final int playerCount;
  final int maxPlayers;
  final DateTime? createdAt;
  final List participants;
  final String? currentPlayer;
  final List<String> currentOrder;
  final int highestBid;
  final dynamic auctionState;
  final int timer;
  final String? hostMode;
  final bool allReadyForResult;
  final DateTime? updatedAt;

  factory RoomModel.fromMap(Map<String, dynamic> map) {
    return RoomModel(
      roomId: map['\$id'] as String? ?? map['roomId'] as String,
      roomCode: (map['roomCode'] ?? '') as String,
      hostId: (map['hostId'] ?? '') as String,
      hostName: (map['hostName'] ?? 'Host') as String,
      status: _statusFromString((map['status'] ?? 'waiting') as String),
      playerCount: ((map['playerCount'] ?? 0) as num).toInt(),
      maxPlayers: ((map['maxPlayers'] ?? 8) as num).toInt(),
      createdAt: map['\$createdAt'] != null
          ? DateTime.tryParse(map['\$createdAt'].toString())
          : (map['createdAt'] != null ? DateTime.tryParse(map['createdAt'].toString()) : null),
      participants: map['participants'] ?? [],
      currentPlayer: map['currentPlayer'] as String?,
      currentOrder: List<String>.from(map['currentOrder'] ?? []),
      highestBid: ((map['highestBid'] ?? 0) as num).toInt(),
      auctionState: map['auctionState'] ?? map['auction_state'],
      timer: ((map['timer'] ?? 0) as num).toInt(),
      hostMode: map['hostMode'] as String?,
      allReadyForResult: (map['allReadyForResult'] ?? false) as bool,
      updatedAt: map['\$updatedAt'] != null
          ? DateTime.tryParse(map['\$updatedAt'].toString())
          : (map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt'].toString()) : null),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roomCode': roomCode,
      'hostId': hostId,
      'hostName': hostName,
      'status': _statusToString(status),
      'playerCount': playerCount,
      'maxPlayers': maxPlayers,
    };
  }

  RoomModel copyWith({
    String? roomCode,
    String? hostId,
    String? hostName,
    RoomStatus? status,
    int? playerCount,
    int? maxPlayers,
    DateTime? createdAt,
    List? participants,
    String? currentPlayer,
    List<String>? currentOrder,
    int? highestBid,
    dynamic auctionState,
    int? timer,
    String? hostMode,
    bool? allReadyForResult,
    DateTime? updatedAt,
  }) {
    return RoomModel(
      roomId: roomId,
      roomCode: roomCode ?? this.roomCode,
      hostId: hostId ?? this.hostId,
      hostName: hostName ?? this.hostName,
      status: status ?? this.status,
      playerCount: playerCount ?? this.playerCount,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      createdAt: createdAt ?? this.createdAt,
      participants: participants ?? this.participants,
      currentPlayer: currentPlayer ?? this.currentPlayer,
      currentOrder: currentOrder ?? this.currentOrder,
      highestBid: highestBid ?? this.highestBid,
      auctionState: auctionState ?? this.auctionState,
      timer: timer ?? this.timer,
      hostMode: hostMode ?? this.hostMode,
      allReadyForResult: allReadyForResult ?? this.allReadyForResult,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static RoomStatus _statusFromString(String value) {
    switch (value) {
      case 'waiting':
        return RoomStatus.waiting;
      case 'in_auction':
        return RoomStatus.inAuction;
      case 'completed':
        return RoomStatus.completed;
      case 'active':
        return RoomStatus.inAuction;
      case 'selection':
        return RoomStatus.waiting;
      default:
        return RoomStatus.waiting;
    }
  }

  static String _statusToString(RoomStatus status) {
    switch (status) {
      case RoomStatus.waiting:
        return 'waiting';
      case RoomStatus.inAuction:
        return 'in_auction';
      case RoomStatus.completed:
        return 'completed';
    }
  }
}
