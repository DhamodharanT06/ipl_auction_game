class BidModel {
  const BidModel({
    required this.id,
    required this.auctionId,
    required this.userId,
    required this.username,
    required this.bidAmount,
    required this.playerName,
    this.timestamp,
    this.updatedAt,
  });

  final String id;
  final String auctionId;
  final String userId;
  final String username;
  final int bidAmount;
  final String playerName;
  final DateTime? timestamp;
  final DateTime? updatedAt;

  factory BidModel.fromMap(Map<String, dynamic> map) {
    return BidModel(
      id: map['\$id'] as String? ?? map['id'] as String,
      auctionId: (map['auctionId'] ?? '') as String,
      userId: (map['userId'] ?? '') as String,
      username: (map['username'] ?? '') as String,
      bidAmount: ((map['bidAmount'] ?? 0) as num).toInt(),
      playerName: (map['playerName'] ?? '') as String,
        timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'].toString())
          : null,
        updatedAt: map['\$updatedAt'] != null
          ? DateTime.tryParse(map['\$updatedAt'].toString())
          : (map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt'].toString()) : null),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'auctionId': auctionId,
      'userId': userId,
      'username': username,
      'bidAmount': bidAmount,
      'playerName': playerName,
      'timestamp': timestamp?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  BidModel copyWith({
    int? bidAmount,
    DateTime? timestamp,
    DateTime? updatedAt,
  }) {
    return BidModel(
      id: id,
      auctionId: auctionId,
      userId: userId,
      username: username,
      bidAmount: bidAmount ?? this.bidAmount,
      playerName: playerName,
      timestamp: timestamp ?? this.timestamp,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
