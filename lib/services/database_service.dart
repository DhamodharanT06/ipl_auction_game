import 'dart:math';

import 'package:appwrite/appwrite.dart';
import 'package:ipl_auction_game/core/config/appwrite_env.dart';
import 'package:ipl_auction_game/models/auction_model.dart';
import 'package:ipl_auction_game/models/bid_model.dart';
import 'package:ipl_auction_game/models/player_model.dart';
import 'package:ipl_auction_game/models/room_model.dart';
import 'package:ipl_auction_game/models/room_player_model.dart';
import 'package:ipl_auction_game/models/user_model.dart';

class DatabaseService {
  DatabaseService(this._databases);

  final Databases _databases;

  Future<String> _roomCodeFor(String roomId) async {
    final room = await getRoom(roomId);
    return room?.roomCode ?? roomId;
  }

  void _logAppwriteError(
    String action,
    Object error,
    StackTrace stackTrace, [
    Map<String, dynamic>? payload,
  ]) {
    print('Appwrite error during $action');
    if (payload != null) {
      print('Payload: $payload');
    }
    print('Error: $error');
    print(stackTrace);
  }

  Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await _databases.getDocument(
        databaseId: AppwriteEnv.databaseId,
        collectionId: AppwriteEnv.usersCollectionId,
        documentId: userId,
      );
      return UserModel.fromMap(doc.data);
    } on AppwriteException {
      return null;
    }
  }

  Future<void> upsertUser(UserModel user) async {
    try {
      await _databases.updateDocument(
        databaseId: AppwriteEnv.databaseId,
        collectionId: AppwriteEnv.usersCollectionId,
        documentId: user.userId,
        data: user.toMap(),
      );
    } on AppwriteException catch (error, stackTrace) {
      _logAppwriteError('upsertUser:update', error, stackTrace, user.toMap());
      await _databases.createDocument(
        databaseId: AppwriteEnv.databaseId,
        collectionId: AppwriteEnv.usersCollectionId,
        documentId: user.userId,
        data: user.toMap(),
      );
    } catch (error, stackTrace) {
      _logAppwriteError('upsertUser', error, stackTrace, user.toMap());
      rethrow;
    }
  }

  Future<RoomModel> createRoom({
    required String hostId,
    required String hostName,
    required int maxPlayers,
  }) async {
    final roomCode = _generateRoomCode();
    final now = DateTime.now().toIso8601String();
    
    final roomPayload = {
      'roomCode': roomCode,
      'hostId': hostId,
      'hostName': hostName,
      'status': 'waiting',
      'playerCount': 1,
      'maxPlayers': maxPlayers,
    };

    final doc = await _databases.createDocument(
      databaseId: AppwriteEnv.databaseId,
      collectionId: AppwriteEnv.roomsCollectionId,
      documentId: ID.unique(),
      data: roomPayload,
      permissions: [
        Permission.read(Role.users()),
        Permission.update(Role.user(hostId)),
        Permission.delete(Role.user(hostId)),
      ],
    );

    // Add host as first room player
    final hostPlayerPayload = {
      'roomId': roomCode,
      'userId': hostId,
      'username': hostName,
      'budget': 1000,
      'isHost': true,
      'isReady': false,
      'joinedAt': now,
    };

    try {
      await _databases.createDocument(
        databaseId: AppwriteEnv.databaseId,
        collectionId: AppwriteEnv.roomPlayersCollectionId,
        documentId: ID.unique(),
        data: hostPlayerPayload,
        permissions: [
          Permission.read(Role.users()),
          Permission.update(Role.user(hostId)),
          Permission.delete(Role.user(hostId)),
        ],
      );
    } on AppwriteException catch (error, stackTrace) {
      _logAppwriteError('createRoom:addHostPlayer', error, stackTrace, hostPlayerPayload);
      rethrow;
    } catch (error, stackTrace) {
      _logAppwriteError('createRoom:addHostPlayer', error, stackTrace, hostPlayerPayload);
      rethrow;
    }

    return RoomModel.fromMap(doc.data..putIfAbsent('\$id', () => doc.$id));
  }

  Future<RoomModel?> getRoom(String roomId) async {
    try {
      final d = await _databases.getDocument(
        databaseId: AppwriteEnv.databaseId,
        collectionId: AppwriteEnv.roomsCollectionId,
        documentId: roomId,
      );
      return RoomModel.fromMap(d.data..putIfAbsent('\$id', () => d.$id));
    } on AppwriteException {
      return null;
    }
  }

  Future<RoomModel?> getRoomByCode(String roomCode) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppwriteEnv.databaseId,
        collectionId: AppwriteEnv.roomsCollectionId,
        queries: [
          Query.equal('roomCode', roomCode),
        ],
      );
      if (response.documents.isEmpty) {
        return null;
      }
      final doc = response.documents.first;
      return RoomModel.fromMap(doc.data..putIfAbsent('\$id', () => doc.$id));
    } on AppwriteException {
      return null;
    }
  }

  Future<void> updateRoom(RoomModel room) async {
    await _databases.updateDocument(
      databaseId: AppwriteEnv.databaseId,
      collectionId: AppwriteEnv.roomsCollectionId,
      documentId: room.roomId,
      data: room.toMap(),
    );
  }

  /// Update arbitrary fields on the room document. Useful for quick updates
  /// like `currentPlayer`, `highestBid`, `timer` without serializing the
  /// entire `RoomModel` via `toMap()`.
  Future<void> updateRoomFields(String roomId, Map<String, dynamic> data) async {
    await _databases.updateDocument(
      databaseId: AppwriteEnv.databaseId,
      collectionId: AppwriteEnv.roomsCollectionId,
      documentId: roomId,
      data: data,
    );
  }

  // ============ ROOM PLAYERS ============
  Future<void> addRoomPlayer({
    required String roomId,
    required String userId,
    required String username,
    required String hostId,
  }) async {
    // Prevent duplicate room-player entries for retry scenarios.
    final existing = await getRoomPlayer(roomId: roomId, userId: userId);
    if (existing != null) {
      return;
    }

    final now = DateTime.now().toIso8601String();
    final roomCode = await _roomCodeFor(roomId);
    final payload = {
      'roomId': roomCode,
      'userId': userId,
      'username': username,
      'budget': 1000,
      'isHost': false,
      'isReady': false,
      'joinedAt': now,
    };

    try {
      await _databases.createDocument(
        databaseId: AppwriteEnv.databaseId,
        collectionId: AppwriteEnv.roomPlayersCollectionId,
        documentId: ID.unique(),
        data: payload,
        permissions: [
          Permission.read(Role.users()),
          Permission.update(Role.user(userId)),
          Permission.delete(Role.user(userId)),
        ],
      );
    } on AppwriteException catch (error, stackTrace) {
      _logAppwriteError('addRoomPlayer', error, stackTrace, payload);
      rethrow;
    } catch (error, stackTrace) {
      _logAppwriteError('addRoomPlayer', error, stackTrace, payload);
      rethrow;
    }

    // Best-effort update of cached room playerCount.
    // Joining should not fail if room update permission is host-only.
    try {
      final room = await getRoom(roomId);
      if (room != null) {
        await updateRoom(room.copyWith(playerCount: room.playerCount + 1));
      }
    } on AppwriteException catch (error, stackTrace) {
      _logAppwriteError('addRoomPlayer:updateRoomCount', error, stackTrace, {
        'roomId': roomId,
        'userId': userId,
      });
    }
  }

  Future<RoomPlayerModel?> getRoomPlayer({
    required String roomId,
    required String userId,
  }) async {
    try {
      final roomCode = await _roomCodeFor(roomId);
      final response = await _databases.listDocuments(
        databaseId: AppwriteEnv.databaseId,
        collectionId: AppwriteEnv.roomPlayersCollectionId,
        queries: [
          Query.equal('roomId', roomCode),
          Query.equal('userId', userId),
        ],
      );
      if (response.documents.isEmpty) {
        return null;
      }
      final doc = response.documents.first;
      return RoomPlayerModel.fromMap(doc.data..putIfAbsent('\$id', () => doc.$id));
    } on AppwriteException {
      return null;
    }
  }

  Future<void> deleteRoomPlayer({
    required String roomId,
    required String userId,
  }) async {
    try {
      final player = await getRoomPlayer(roomId: roomId, userId: userId);
      if (player == null) {
        return;
      }
      await _databases.deleteDocument(
        databaseId: AppwriteEnv.databaseId,
        collectionId: AppwriteEnv.roomPlayersCollectionId,
        documentId: player.id,
      );
      final room = await getRoom(roomId);
      if (room != null) {
        await updateRoom(room.copyWith(playerCount: (room.playerCount - 1).clamp(0, 999)));
      }
    } on AppwriteException {
      // Ignore cleanup errors when the room is already gone.
    }
  }

  Future<void> transferHost({
    required String roomId,
    required String newHostId,
    required String newHostName,
  }) async {
    final room = await getRoom(roomId);
    if (room == null) {
      return;
    }

    await updateRoom(
      room.copyWith(
        hostId: newHostId,
        hostName: newHostName,
      ),
    );

    final player = await getRoomPlayer(roomId: roomId, userId: newHostId);
    if (player != null) {
      await _databases.updateDocument(
        databaseId: AppwriteEnv.databaseId,
        collectionId: AppwriteEnv.roomPlayersCollectionId,
        documentId: player.id,
        data: {'isHost': true},
      );
    }
  }

  Future<void> deleteRoom(String roomId) async {
    try {
      final roomCode = await _roomCodeFor(roomId);
      final roomPlayers = await getRoomPlayers(roomId);
      for (final player in roomPlayers) {
        await _databases.deleteDocument(
          databaseId: AppwriteEnv.databaseId,
          collectionId: AppwriteEnv.roomPlayersCollectionId,
          documentId: player.id,
        );
      }

      final auctions = await _databases.listDocuments(
        databaseId: AppwriteEnv.databaseId,
        collectionId: AppwriteEnv.auctionsCollectionId,
        queries: [Query.equal('roomId', roomCode)],
      );

      for (final auctionDoc in auctions.documents) {
        final bids = await _databases.listDocuments(
          databaseId: AppwriteEnv.databaseId,
          collectionId: AppwriteEnv.bidsCollectionId,
          queries: [Query.equal('auctionId', auctionDoc.$id)],
        );
        for (final bidDoc in bids.documents) {
          await _databases.deleteDocument(
            databaseId: AppwriteEnv.databaseId,
            collectionId: AppwriteEnv.bidsCollectionId,
            documentId: bidDoc.$id,
          );
        }
        await _databases.deleteDocument(
          databaseId: AppwriteEnv.databaseId,
          collectionId: AppwriteEnv.auctionsCollectionId,
          documentId: auctionDoc.$id,
        );
      }

      final room = await getRoom(roomId);
      if (room != null) {
        await _databases.deleteDocument(
          databaseId: AppwriteEnv.databaseId,
          collectionId: AppwriteEnv.roomsCollectionId,
          documentId: room.roomId,
        );
      }
    } on AppwriteException {
      // Ignore cleanup errors when the room has already been removed.
    }
  }

  Future<List<RoomPlayerModel>> getRoomPlayers(String roomId) async {
    try {
      final roomCode = await _roomCodeFor(roomId);
      final response = await _databases.listDocuments(
        databaseId: AppwriteEnv.databaseId,
        collectionId: AppwriteEnv.roomPlayersCollectionId,
        queries: [
          Query.equal('roomId', roomCode),
        ],
      );
      return response.documents.map((doc) {
        return RoomPlayerModel.fromMap(doc.data..putIfAbsent('\$id', () => doc.$id));
      }).toList();
    } on AppwriteException {
      return [];
    }
  }

  Future<void> updateRoomPlayer({
    required String roomId,
    required String userId,
    bool? isReady,
    String? teamName,
    bool? teamConfirmed,
    int? budget,
  }) async {
    try {
      final roomCode = await _roomCodeFor(roomId);
      final response = await _databases.listDocuments(
        databaseId: AppwriteEnv.databaseId,
        collectionId: AppwriteEnv.roomPlayersCollectionId,
        queries: [
          Query.equal('roomId', roomCode),
          Query.equal('userId', userId),
        ],
      );
      if (response.documents.isNotEmpty) {
        final doc = response.documents.first;
        final data = <String, dynamic>{};
        if (isReady != null) data['isReady'] = isReady;
        if (teamName != null) {
          final duplicate = await _databases.listDocuments(
            databaseId: AppwriteEnv.databaseId,
            collectionId: AppwriteEnv.roomPlayersCollectionId,
            queries: [
              Query.equal('roomId', roomCode),
              Query.equal('teamName', teamName),
              Query.notEqual('userId', userId),
            ],
          );
          if (duplicate.documents.isNotEmpty) {
            throw StateError('That franchise is already taken');
          }
          data['teamName'] = teamName;
          // Auto-mark as ready when selecting a team
          data['isReady'] = true;
        }
        if (budget != null) data['budget'] = budget;

        if (data.isNotEmpty) {
          await _databases.updateDocument(
            databaseId: AppwriteEnv.databaseId,
            collectionId: AppwriteEnv.roomPlayersCollectionId,
            documentId: doc.$id,
            data: data,
          );
        }
      }
    } on AppwriteException catch (error, stackTrace) {
      _logAppwriteError('updateRoomPlayer', error, stackTrace, {
        'roomId': roomId,
        'userId': userId,
        if (isReady != null) 'isReady': isReady,
        if (teamName != null) 'teamName': teamName,
        if (budget != null) 'budget': budget,
      });
      rethrow;
    } catch (error, stackTrace) {
      _logAppwriteError('updateRoomPlayer', error, stackTrace, {
        'roomId': roomId,
        'userId': userId,
        if (isReady != null) 'isReady': isReady,
        if (teamName != null) 'teamName': teamName,
        if (budget != null) 'budget': budget,
      });
      rethrow;
    }
  }

  Future<void> assignTeamsRandomly(RoomModel room) async {
    final players = await getRoomPlayers(room.roomId);
    final approvedPlayers = players.where((player) => player.isReady).toList()
      ..sort((a, b) {
        final aJoined = a.joinedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bJoined = b.joinedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return aJoined.compareTo(bJoined);
      });

    const teams = [
      'MI', 'CSK', 'RCB', 'KKR', 'SRH',
      'DC', 'RR', 'PBKS', 'GT', 'LSG',
    ];

    final alreadyAssigned = approvedPlayers.any((player) => player.teamName != null && player.teamName!.isNotEmpty);
    if (alreadyAssigned) {
      return;
    }

    if (approvedPlayers.length > teams.length) {
      throw StateError('More approved players than available IPL franchises');
    }

    final shuffledTeams = List<String>.from(teams)..shuffle();

    for (var i = 0; i < approvedPlayers.length; i++) {
      await updateRoomPlayer(
        roomId: room.roomId,
        userId: approvedPlayers[i].userId,
        teamName: shuffledTeams[i],
      );
    }
  }

  // ============ AUCTIONS ============
  Future<AuctionModel> createAuction({
    required String roomId,
  }) async {
    final now = DateTime.now().toIso8601String();
    final roomCode = await _roomCodeFor(roomId);
    
    final doc = await _databases.createDocument(
      databaseId: AppwriteEnv.databaseId,
      collectionId: AppwriteEnv.auctionsCollectionId,
      documentId: ID.unique(),
      data: {
        'roomId': roomCode,
        'currentPlayerIndex': 0,
        'currentBid': 0,
        'currentBidder': null,
        'currentBidderTeam': null,
        'status': 'active',
        'startedAt': now,
      },
      permissions: [
        Permission.read(Role.users()),
        Permission.update(Role.users()),
        Permission.delete(Role.users()),
      ],
    );

    return AuctionModel.fromMap(doc.data..putIfAbsent('\$id', () => doc.$id));
  }

  Future<AuctionModel?> getAuction(String auctionId) async {
    try {
      final doc = await _databases.getDocument(
        databaseId: AppwriteEnv.databaseId,
        collectionId: AppwriteEnv.auctionsCollectionId,
        documentId: auctionId,
      );
      return AuctionModel.fromMap(doc.data..putIfAbsent('\$id', () => doc.$id));
    } on AppwriteException {
      return null;
    }
  }

  Future<AuctionModel?> getAuctionForRoom(String roomId) async {
    try {
      final roomCode = await _roomCodeFor(roomId);
      final response = await _databases.listDocuments(
        databaseId: AppwriteEnv.databaseId,
        collectionId: AppwriteEnv.auctionsCollectionId,
        queries: [
          Query.equal('roomId', roomCode),
          Query.notEqual('status', 'completed'),
        ],
      );
      if (response.documents.isEmpty) {
        return null;
      }
      final doc = response.documents.first;
      return AuctionModel.fromMap(doc.data..putIfAbsent('\$id', () => doc.$id));
    } on AppwriteException {
      return null;
    }
  }

  Future<void> updateAuction(AuctionModel auction) async {
    await _databases.updateDocument(
      databaseId: AppwriteEnv.databaseId,
      collectionId: AppwriteEnv.auctionsCollectionId,
      documentId: auction.id,
      data: auction.toMap(),
    );
  }

  // ============ BIDS ============
  Future<void> placeBid({
    required String auctionId,
    required String userId,
    required String username,
    required int bidAmount,
    required String playerName,
  }) async {
    final now = DateTime.now().toIso8601String();
    
    await _databases.createDocument(
      databaseId: AppwriteEnv.databaseId,
      collectionId: AppwriteEnv.bidsCollectionId,
      documentId: ID.unique(),
      data: {
        'auctionId': auctionId,
        'userId': userId,
        'username': username,
        'bidAmount': bidAmount,
        'playerName': playerName,
        'timestamp': now,
      },
      permissions: [
        Permission.read(Role.users()),
        Permission.write(Role.user(userId)),
        Permission.delete(Role.user(userId)),
      ],
    );
  }

  Future<List<BidModel>> getBidsForAuction(String auctionId) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppwriteEnv.databaseId,
        collectionId: AppwriteEnv.bidsCollectionId,
        queries: [
          Query.equal('auctionId', auctionId),
          Query.orderDesc('timestamp'),
        ],
      );
      return response.documents.map((doc) {
        return BidModel.fromMap(doc.data..putIfAbsent('\$id', () => doc.$id));
      }).toList();
    } on AppwriteException {
      return [];
    }
  }

  Future<List<BidModel>> getBidsForPlayer(String auctionId, String playerName) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppwriteEnv.databaseId,
        collectionId: AppwriteEnv.bidsCollectionId,
        queries: [
          Query.equal('auctionId', auctionId),
          Query.equal('playerName', playerName),
          Query.orderDesc('timestamp'),
        ],
      );
      return response.documents.map((doc) {
        return BidModel.fromMap(doc.data..putIfAbsent('\$id', () => doc.$id));
      }).toList();
    } on AppwriteException {
      return [];
    }
  }

  // ============ PLAYERS ============
  Future<void> createOrUpdatePlayer(PlayerModel player) async {
    try {
      await _databases.updateDocument(
        databaseId: AppwriteEnv.databaseId,
        collectionId: AppwriteEnv.playersCollectionId,
        documentId: player.playerId,
        data: player.toMap(),
      );
    } on AppwriteException {
      await _databases.createDocument(
        databaseId: AppwriteEnv.databaseId,
        collectionId: AppwriteEnv.playersCollectionId,
        documentId: player.playerId,
        data: player.toMap(),
        permissions: [
          Permission.read(Role.users()),
          Permission.update(Role.users()),
          Permission.delete(Role.users()),
        ],
      );
    }
  }

  Future<PlayerModel?> getPlayer(String playerId) async {
    try {
      final doc = await _databases.getDocument(
        databaseId: AppwriteEnv.databaseId,
        collectionId: AppwriteEnv.playersCollectionId,
        documentId: playerId,
      );
      return PlayerModel.fromMap(doc.data..putIfAbsent('\$id', () => doc.$id));
    } on AppwriteException {
      return null;
    }
  }

  Future<List<PlayerModel>> getAllPlayers() async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppwriteEnv.databaseId,
        collectionId: AppwriteEnv.playersCollectionId,
      );
      return response.documents.map((doc) {
        return PlayerModel.fromMap(doc.data..putIfAbsent('\$id', () => doc.$id));
      }).toList();
    } on AppwriteException {
      return [];
    }
  }

  Future<List<PlayerModel>> getPlayersByRole(String role) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppwriteEnv.databaseId,
        collectionId: AppwriteEnv.playersCollectionId,
        queries: [
          Query.equal('role', role),
        ],
      );
      return response.documents.map((doc) {
        return PlayerModel.fromMap(doc.data..putIfAbsent('\$id', () => doc.$id));
      }).toList();
    } on AppwriteException {
      return [];
    }
  }

  // ============ SELECTION ============
  Future<void> savePlayerSelection({
    required String roomId,
    required String userId,
    required List<String> selectedPlayerIds,
    required String captainId,
    required String viceCaptainId,
  }) async {
    // Store selection data - can extend to a selections collection in future
    await updateRoomPlayer(
      roomId: roomId,
      userId: userId,
    );
  }

  // ============ HELPERS ============
  String _generateRoomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)])
        .join();
  }
}
