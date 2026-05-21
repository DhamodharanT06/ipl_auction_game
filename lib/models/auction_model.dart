enum AuctionStatus { active, paused, completed }

class AuctionModel {
  const AuctionModel({
    required this.id,
    required this.roomId,
    this.currentPlayerIndex = 0,
    this.currentBid = 0,
    this.currentBidder,
    this.currentBidderTeam,
    this.status = AuctionStatus.active,
    this.startedAt,
    this.updatedAt,
  });

  final String id;
  final String roomId;
  final int currentPlayerIndex;
  final int currentBid;
  final String? currentBidder;
  final String? currentBidderTeam;
  final AuctionStatus status;
  final DateTime? startedAt;
  final DateTime? updatedAt;

  factory AuctionModel.fromMap(Map<String, dynamic> map) {
    return AuctionModel(
      id: map['\$id'] as String? ?? map['id'] as String,
      roomId: (map['roomId'] ?? '') as String,
      currentPlayerIndex: ((map['currentPlayerIndex'] ?? 0) as num).toInt(),
      currentBid: ((map['currentBid'] ?? 0) as num).toInt(),
      currentBidder: map['currentBidder'] as String?,
      currentBidderTeam: map['currentBidderTeam'] as String?,
      status: _statusFromString((map['status'] ?? 'active') as String),
        startedAt: map['startedAt'] != null
          ? DateTime.tryParse(map['startedAt'].toString())
          : (map['\$createdAt'] != null ? DateTime.tryParse(map['\$createdAt'].toString()) : null),
        updatedAt: map['\$updatedAt'] != null
          ? DateTime.tryParse(map['\$updatedAt'].toString())
          : (map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt'].toString()) : null),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'currentPlayerIndex': currentPlayerIndex,
      'currentBid': currentBid,
      'currentBidder': currentBidder,
      'currentBidderTeam': currentBidderTeam,
      'status': status.name,
      'startedAt': startedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  AuctionModel copyWith({
    int? currentPlayerIndex,
    int? currentBid,
    String? currentBidder,
    String? currentBidderTeam,
    AuctionStatus? status,
    DateTime? updatedAt,
  }) {
    return AuctionModel(
      id: id,
      roomId: roomId,
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      currentBid: currentBid ?? this.currentBid,
      currentBidder: currentBidder ?? this.currentBidder,
      currentBidderTeam: currentBidderTeam ?? this.currentBidderTeam,
      status: status ?? this.status,
      startedAt: startedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static AuctionStatus _statusFromString(String value) {
    switch (value) {
      case 'paused':
        return AuctionStatus.paused;
      case 'completed':
        return AuctionStatus.completed;
      default:
        return AuctionStatus.active;
    }
  }
}
