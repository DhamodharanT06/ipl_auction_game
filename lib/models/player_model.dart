class PlayerModel {
  const PlayerModel({
    required this.playerId,
    required this.name,
    required this.role,
    required this.avgScore,
    this.isForeign = false,
    required this.basePrice,
    this.imageUrl,
    this.country,
  });

  final String playerId;
  final String name;
  final String role;
  final int avgScore;
  final bool isForeign;
  final int basePrice;
  final String? imageUrl;
  final String? country;

  bool get isWicketKeeper => role.toLowerCase().contains('wk');

  factory PlayerModel.fromMap(Map<String, dynamic> map) {
    return PlayerModel(
      playerId: map['\$id'] as String? ?? map['playerId'].toString(),
      name: (map['name'] ?? '').toString(),
      role: (map['role'] ?? '').toString(),
      avgScore: ((map['avgScore'] ?? 0) as num).toInt(),
      isForeign: (map['isForeign'] ?? false) as bool,
      basePrice: ((map['basePrice'] ?? 0) as num).toInt(),
      imageUrl: map['imageUrl'] as String?,
      country: map['country'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'role': role,
      'avgScore': avgScore,
      'isForeign': isForeign,
      'basePrice': basePrice,
      'imageUrl': imageUrl,
      'country': country,
    };
  }

  PlayerModel copyWith({
    String? name,
    String? role,
    int? avgScore,
    bool? isForeign,
    int? basePrice,
    String? imageUrl,
    String? country,
  }) {
    return PlayerModel(
      playerId: playerId,
      name: name ?? this.name,
      role: role ?? this.role,
      avgScore: avgScore ?? this.avgScore,
      isForeign: isForeign ?? this.isForeign,
      basePrice: basePrice ?? this.basePrice,
      imageUrl: imageUrl ?? this.imageUrl,
      country: country ?? this.country,
    );
  }
}
