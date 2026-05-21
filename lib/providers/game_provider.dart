import 'dart:async';
import 'package:flutter/material.dart';
// APPWRITE: import '../services/appwrite_service.dart';
import '../models/game_models.dart';

/// ============================================================
/// DUMMY MODE ENABLED - Uncomment APPWRITE lines for production
/// ============================================================
class GameProvider with ChangeNotifier {
  // APPWRITE: final AppwriteService _appwriteService = AppwriteService();
  
  Room? _currentRoom;
  List<RoomPlayer> _roomPlayers = [];
  AuctionState? _currentAuction;
  RoomPlayer? _currentRoomPlayer;
  
  // APPWRITE: StreamSubscription? _roomSubscription;
  // APPWRITE: StreamSubscription? _playersSubscription;
  // APPWRITE: StreamSubscription? _auctionSubscription;

  bool _isLoading = false;
  String? _error;

  Room? get currentRoom => _currentRoom;
  List<RoomPlayer> get roomPlayers => _roomPlayers;
  AuctionState? get currentAuction => _currentAuction;
  RoomPlayer? get currentRoomPlayer => _currentRoomPlayer;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isHost => _currentRoomPlayer?.isHost ?? false;
  bool get allPlayersReady => _roomPlayers.isNotEmpty && 
      _roomPlayers.every((p) => p.isReady || p.isHost);

  // DUMMY: Sample players for auction
  final List<Map<String, dynamic>> _dummyPlayers = [
    {'name': 'Virat Kohli', 'role': 'Batsman', 'avgScore': 95, 'isForeign': false},
    {'name': 'Rohit Sharma', 'role': 'Batsman', 'avgScore': 94, 'isForeign': false},
    {'name': 'MS Dhoni', 'role': 'WK-Batsman', 'avgScore': 92, 'isForeign': false},
    {'name': 'Jasprit Bumrah', 'role': 'Bowler', 'avgScore': 96, 'isForeign': false},
    {'name': 'Hardik Pandya', 'role': 'All-rounder', 'avgScore': 88, 'isForeign': false},
    {'name': 'Rishabh Pant', 'role': 'WK-Batsman', 'avgScore': 88, 'isForeign': false},
    {'name': 'KL Rahul', 'role': 'Batsman', 'avgScore': 89, 'isForeign': false},
    {'name': 'Ravindra Jadeja', 'role': 'All-rounder', 'avgScore': 90, 'isForeign': false},
    {'name': 'AB de Villiers', 'role': 'Batsman', 'avgScore': 94, 'isForeign': true},
    {'name': 'David Warner', 'role': 'Batsman', 'avgScore': 91, 'isForeign': true},
    {'name': 'Glenn Maxwell', 'role': 'All-rounder', 'avgScore': 88, 'isForeign': true},
    {'name': 'Rashid Khan', 'role': 'Bowler', 'avgScore': 91, 'isForeign': true},
    {'name': 'Jos Buttler', 'role': 'WK-Batsman', 'avgScore': 92, 'isForeign': true},
    {'name': 'Pat Cummins', 'role': 'Bowler', 'avgScore': 90, 'isForeign': true},
    {'name': 'Ben Stokes', 'role': 'All-rounder', 'avgScore': 90, 'isForeign': true},
  ];

  // Create a new room
  Future<bool> createRoom(String oderId, String username) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Generate room code
      final roomCode = _generateRoomCode();

      /* APPWRITE:
      final roomDoc = await _appwriteService.createRoom(
        roomCode: roomCode,
        hostId: userId,
        hostName: username,
      );
      _currentRoom = Room.fromMap(roomDoc.data, roomDoc.\$id);

      final playerDoc = await _appwriteService.addPlayerToRoom(
        roomId: roomDoc.\$id,
        userId: userId,
        username: username,
      );
      await _appwriteService.updateRoomPlayer(playerDoc.\$id, {'isHost': true});
      _currentRoomPlayer = RoomPlayer.fromMap(playerDoc.data, playerDoc.\$id);
      await loadRoomPlayers(roomDoc.\$id);
      _subscribeToRoomUpdates();
      */

      // DUMMY: Create room locally
      await Future.delayed(const Duration(milliseconds: 500));
      
      _currentRoom = Room(
        id: 'room_${DateTime.now().millisecondsSinceEpoch}',
        roomCode: roomCode,
        hostId: oderId,
        hostName: username,
        status: 'waiting',
        maxPlayers: 8,
        playerCount: 1,
        createdAt: DateTime.now(),
      );

      _currentRoomPlayer = RoomPlayer(
        id: 'player_host',
        roomId: _currentRoom!.id,
        userId: oderId,
        username: username,
        teamName: 'Team $username',
        budget: 1000,
        isHost: true,
        isReady: true,
        playersOwned: [],
        joinedAt: DateTime.now(),
      );

      _roomPlayers = [_currentRoomPlayer!];
      
      // DUMMY: Add some fake players after a delay
      _addDummyPlayersToRoom();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // DUMMY: Simulate other players joining
  void _addDummyPlayersToRoom() {
    Future.delayed(const Duration(seconds: 2), () {
      if (_currentRoom == null) return;
      
      _roomPlayers.add(RoomPlayer(
        id: 'player_2',
        roomId: _currentRoom!.id,
        userId: 'user_2',
        username: 'CricketFan99',
        teamName: 'Super Kings',
        budget: 1000,
        isHost: false,
        isReady: false,
        playersOwned: [],
        joinedAt: DateTime.now(),
      ));
      notifyListeners();
    });

    Future.delayed(const Duration(seconds: 4), () {
      if (_currentRoom == null) return;
      
      _roomPlayers.add(RoomPlayer(
        id: 'player_3',
        roomId: _currentRoom!.id,
        userId: 'user_3',
        username: 'IPLMaster',
        teamName: 'Royal Challengers',
        budget: 1000,
        isHost: false,
        isReady: false,
        playersOwned: [],
        joinedAt: DateTime.now(),
      ));
      notifyListeners();
    });

    Future.delayed(const Duration(seconds: 5), () {
      if (_currentRoom == null || _roomPlayers.length < 2) return;
      // Mark second player as ready
      final idx = _roomPlayers.indexWhere((p) => p.id == 'player_2');
      if (idx != -1) {
        _roomPlayers[idx] = _roomPlayers[idx].copyWith(isReady: true);
        notifyListeners();
      }
    });

    Future.delayed(const Duration(seconds: 7), () {
      if (_currentRoom == null || _roomPlayers.length < 3) return;
      // Mark third player as ready
      final idx = _roomPlayers.indexWhere((p) => p.id == 'player_3');
      if (idx != -1) {
        _roomPlayers[idx] = _roomPlayers[idx].copyWith(isReady: true);
        notifyListeners();
      }
    });
  }

  // Join an existing room
  Future<bool> joinRoom(String roomCode, String userId, String username) async {
    try {
      _isLoading = true;
      notifyListeners();

      /* APPWRITE:
      final roomDocs = await _appwriteService.getRoomByCode(roomCode);
      if (roomDocs.documents.isEmpty) {
        _error = 'Room not found';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      final roomDoc = roomDocs.documents.first;
      _currentRoom = Room.fromMap(roomDoc.data, roomDoc.\$id);
      
      if (_currentRoom!.playerCount >= _currentRoom!.maxPlayers) {
        _error = 'Room is full';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final playerDoc = await _appwriteService.addPlayerToRoom(
        roomId: roomDoc.\$id,
        userId: userId,
        username: username,
      );
      _currentRoomPlayer = RoomPlayer.fromMap(playerDoc.data, playerDoc.\$id);
      await _appwriteService.updateRoom(
        roomDoc.\$id,
        {'playerCount': _currentRoom!.playerCount + 1},
      );
      await loadRoomPlayers(roomDoc.\$id);
      _subscribeToRoomUpdates();
      */

      // DUMMY: Simulate joining a room
      await Future.delayed(const Duration(milliseconds: 800));
      
      // DUMMY: Accept any room code for testing
      _currentRoom = Room(
        id: 'room_joined_123',
        roomCode: roomCode.toUpperCase(),
        hostId: 'host_user',
        hostName: 'HostPlayer',
        status: 'waiting',
        maxPlayers: 8,
        playerCount: 3,
        createdAt: DateTime.now(),
      );

      _currentRoomPlayer = RoomPlayer(
        id: 'player_joined',
        roomId: _currentRoom!.id,
        userId: userId,
        username: username,
        teamName: 'Team $username',
        budget: 1000,
        isHost: false,
        isReady: false,
        playersOwned: [],
        joinedAt: DateTime.now(),
      );

      _roomPlayers = [
        RoomPlayer(
          id: 'player_host',
          roomId: _currentRoom!.id,
          userId: 'host_user',
          username: 'HostPlayer',
          teamName: 'Mumbai Indians',
          budget: 1000,
          isHost: true,
          isReady: true,
          playersOwned: [],
          joinedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
        RoomPlayer(
          id: 'player_existing',
          roomId: _currentRoom!.id,
          userId: 'user_existing',
          username: 'CricketKing',
          teamName: 'Chennai Kings',
          budget: 1000,
          isHost: false,
          isReady: true,
          playersOwned: [],
          joinedAt: DateTime.now().subtract(const Duration(minutes: 2)),
        ),
        _currentRoomPlayer!,
      ];

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Load room players
  Future<void> loadRoomPlayers(String roomId) async {
    /* APPWRITE:
    try {
      final playerDocs = await _appwriteService.getRoomPlayers(roomId);
      _roomPlayers = playerDocs.documents
          .map((doc) => RoomPlayer.fromMap(doc.data, doc.\$id))
          .toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
    */
    // DUMMY: Already loaded locally
    notifyListeners();
  }

  // Toggle ready status
  Future<void> toggleReady() async {
    if (_currentRoomPlayer == null) return;

    /* APPWRITE:
    try {
      final newReadyStatus = !_currentRoomPlayer!.isReady;
      await _appwriteService.updateRoomPlayer(
        _currentRoomPlayer!.id,
        {'isReady': newReadyStatus},
      );
      _currentRoomPlayer = _currentRoomPlayer!.copyWith(isReady: newReadyStatus);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
    */

    // DUMMY: Toggle locally
    final newReadyStatus = !_currentRoomPlayer!.isReady;
    _currentRoomPlayer = _currentRoomPlayer!.copyWith(isReady: newReadyStatus);
    
    // Update in the list too
    final idx = _roomPlayers.indexWhere((p) => p.id == _currentRoomPlayer!.id);
    if (idx != -1) {
      _roomPlayers[idx] = _currentRoomPlayer!;
    }
    notifyListeners();
  }

  // Start auction (host only)
  Future<bool> startAuction() async {
    if (_currentRoom == null || !isHost) return false;

    try {
      _isLoading = true;
      notifyListeners();

      /* APPWRITE:
      final players = _generateAuctionPlayers();
      final auctionDoc = await _appwriteService.createAuction(
        roomId: _currentRoom!.id,
        players: players,
      );
      _currentAuction = AuctionState.fromMap(auctionDoc.data, auctionDoc.\$id);
      await _appwriteService.updateRoom(
        _currentRoom!.id,
        {'status': 'in_auction'},
      );
      _subscribeToAuctionUpdates();
      */

      // DUMMY: Create auction locally
      await Future.delayed(const Duration(milliseconds: 500));
      
      _currentAuction = AuctionState(
        id: 'auction_${DateTime.now().millisecondsSinceEpoch}',
        roomId: _currentRoom!.id,
        players: _dummyPlayers,
        currentPlayerIndex: 0,
        currentBid: 20, // Base price
        currentBidder: '',
        currentBidderTeam: '',
        status: 'active',
        countdownPhase: 0,
        startedAt: DateTime.now(),
      );

      _currentRoom = Room(
        id: _currentRoom!.id,
        roomCode: _currentRoom!.roomCode,
        hostId: _currentRoom!.hostId,
        hostName: _currentRoom!.hostName,
        status: 'in_auction',
        maxPlayers: _currentRoom!.maxPlayers,
        playerCount: _currentRoom!.playerCount,
        createdAt: _currentRoom!.createdAt,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Place a bid
  Future<bool> placeBid(int bidAmount) async {
    if (_currentAuction == null || _currentRoomPlayer == null) return false;

    // Validate bid
    if (bidAmount <= _currentAuction!.currentBid) {
      _error = 'Bid must be higher than current bid';
      notifyListeners();
      return false;
    }

    if (bidAmount > _currentRoomPlayer!.budget) {
      _error = 'Insufficient budget';
      notifyListeners();
      return false;
    }

    /* APPWRITE:
    try {
      await _appwriteService.updateAuction(
        _currentAuction!.id,
        {
          'currentBid': bidAmount,
          'currentBidder': _currentRoomPlayer!.username,
          'currentBidderTeam': _currentRoomPlayer!.teamName,
          'countdownPhase': 0,
        },
      );
      await _appwriteService.createBid(
        auctionId: _currentAuction!.id,
        userId: _currentRoomPlayer!.userId,
        username: _currentRoomPlayer!.username,
        bidAmount: bidAmount,
        playerName: _currentAuction!.currentPlayer.name,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
    */

    // DUMMY: Update auction locally
    _currentAuction = AuctionState(
      id: _currentAuction!.id,
      roomId: _currentAuction!.roomId,
      players: _currentAuction!.players,
      currentPlayerIndex: _currentAuction!.currentPlayerIndex,
      currentBid: bidAmount,
      currentBidder: _currentRoomPlayer!.username,
      currentBidderTeam: _currentRoomPlayer!.teamName,
      status: _currentAuction!.status,
      countdownPhase: 0,
      startedAt: _currentAuction!.startedAt,
    );
    notifyListeners();

    // DUMMY: Simulate other players bidding back
    _simulateOtherBids(bidAmount);

    return true;
  }

  // DUMMY: Simulate other players placing bids
  void _simulateOtherBids(int lastBid) {
    if (_currentAuction == null) return;
    
    // 50% chance another player bids
    if (DateTime.now().millisecond % 2 == 0 && lastBid < 200) {
      Future.delayed(const Duration(seconds: 2), () {
        if (_currentAuction == null) return;
        final newBid = lastBid + 10;
        final otherPlayer = _roomPlayers.firstWhere(
          (p) => p.id != _currentRoomPlayer?.id && !p.isHost,
          orElse: () => _roomPlayers.first,
        );
        
        _currentAuction = AuctionState(
          id: _currentAuction!.id,
          roomId: _currentAuction!.roomId,
          players: _currentAuction!.players,
          currentPlayerIndex: _currentAuction!.currentPlayerIndex,
          currentBid: newBid,
          currentBidder: otherPlayer.username,
          currentBidderTeam: otherPlayer.teamName,
          status: _currentAuction!.status,
          countdownPhase: 0,
          startedAt: _currentAuction!.startedAt,
        );
        notifyListeners();
      });
    }
  }

  // Sell player to highest bidder
  Future<void> sellPlayer() async {
    if (_currentAuction == null) return;

    /* APPWRITE:
    try {
      final currentPlayer = _currentAuction!.currentPlayer;
      final winningPlayer = _roomPlayers.firstWhere(
        (p) => p.username == _currentAuction!.currentBidder,
      );
      
      final updatedOwned = List<Map<String, dynamic>>.from(winningPlayer.playersOwned)
        ..add({
          'name': currentPlayer.name,
          'cost': _currentAuction!.currentBid,
          'role': currentPlayer.role,
          'isForeign': currentPlayer.isForeign,
        });
      final newBudget = winningPlayer.budget - _currentAuction!.currentBid;
      
      await _appwriteService.updateRoomPlayer(
        winningPlayer.id,
        {
          'playersOwned': updatedOwned,
          'budget': newBudget,
        },
      );
      await _moveToNextPlayer();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
    */

    // DUMMY: Update locally
    if (_currentAuction!.currentBidder.isNotEmpty) {
      final winnerIdx = _roomPlayers.indexWhere(
        (p) => p.username == _currentAuction!.currentBidder,
      );
      
      if (winnerIdx != -1) {
        final winner = _roomPlayers[winnerIdx];
        final currentPlayerData = _currentAuction!.players[_currentAuction!.currentPlayerIndex];
        final newOwned = List<Map<String, dynamic>>.from(winner.playersOwned)
          ..add({
            'name': currentPlayerData['name'],
            'cost': _currentAuction!.currentBid,
            'role': currentPlayerData['role'],
            'isForeign': currentPlayerData['isForeign'],
          });
        
        _roomPlayers[winnerIdx] = RoomPlayer(
          id: winner.id,
          roomId: winner.roomId,
          userId: winner.userId,
          username: winner.username,
          teamName: winner.teamName,
          budget: winner.budget - _currentAuction!.currentBid,
          isHost: winner.isHost,
          isReady: winner.isReady,
          playersOwned: newOwned,
          joinedAt: winner.joinedAt,
        );
      }
    }

    await _moveToNextPlayer();
  }

  // Move to next player
  Future<void> _moveToNextPlayer() async {
    if (_currentAuction == null) return;

    /* APPWRITE:
    try {
      if (_currentAuction!.hasMorePlayers) {
        await _appwriteService.updateAuction(
          _currentAuction!.id,
          {
            'currentPlayerIndex': _currentAuction!.currentPlayerIndex + 1,
            'currentBid': 0,
            'currentBidder': '',
            'currentBidderTeam': '',
            'countdownPhase': 0,
          },
        );
      } else {
        await _appwriteService.updateAuction(
          _currentAuction!.id,
          {'status': 'completed'},
        );
        await _appwriteService.updateRoom(
          _currentRoom!.id,
          {'status': 'completed'},
        );
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
    */

    // DUMMY: Move to next player locally
    if (_currentAuction!.hasMorePlayers) {
      _currentAuction = AuctionState(
        id: _currentAuction!.id,
        roomId: _currentAuction!.roomId,
        players: _currentAuction!.players,
        currentPlayerIndex: _currentAuction!.currentPlayerIndex + 1,
        currentBid: 20, // Reset to base price
        currentBidder: '',
        currentBidderTeam: '',
        status: 'active',
        countdownPhase: 0,
        startedAt: _currentAuction!.startedAt,
      );
    } else {
      _currentAuction = AuctionState(
        id: _currentAuction!.id,
        roomId: _currentAuction!.roomId,
        players: _currentAuction!.players,
        currentPlayerIndex: _currentAuction!.currentPlayerIndex,
        currentBid: _currentAuction!.currentBid,
        currentBidder: _currentAuction!.currentBidder,
        currentBidderTeam: _currentAuction!.currentBidderTeam,
        status: 'completed',
        countdownPhase: 0,
        startedAt: _currentAuction!.startedAt,
      );
    }
    notifyListeners();
  }

  /* APPWRITE:
  void _subscribeToRoomUpdates() {
    if (_currentRoom == null) return;
    _appwriteService.subscribeToRoomPlayers(
      _currentRoom!.id,
      (message) {
        loadRoomPlayers(_currentRoom!.id);
      },
    );
  }

  void _subscribeToAuctionUpdates() {
    if (_currentAuction == null) return;
    _appwriteService.subscribeToAuction(
      _currentAuction!.id,
      (message) async {
        try {
          final auctionDoc = await _appwriteService.getAuction(_currentRoom!.id);
          _currentAuction = AuctionState.fromMap(auctionDoc.data, auctionDoc.\$id);
          notifyListeners();
        } catch (e) {
          // Handle error
        }
      },
    );
  }
  */

  // Generate room code
  String _generateRoomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(6, (i) => chars[(random + i * 7) % chars.length]).join();
  }

  /* APPWRITE:
  List<Map<String, dynamic>> _generateAuctionPlayers() {
    return _dummyPlayers;
  }
  */

  // Leave room
  Future<void> leaveRoom() async {
    /* APPWRITE:
    if (_currentRoomPlayer == null) return;
    try {
      await _appwriteService.removePlayerFromRoom(_currentRoomPlayer!.id);
      if (_currentRoom != null) {
        await _appwriteService.updateRoom(
          _currentRoom!.id,
          {'playerCount': _currentRoom!.playerCount - 1},
        );
      }
      _cleanup();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
    */

    // DUMMY: Just cleanup locally
    _cleanup();
  }

  void _cleanup() {
    // APPWRITE: _roomSubscription?.cancel();
    // APPWRITE: _playersSubscription?.cancel();
    // APPWRITE: _auctionSubscription?.cancel();
    _currentRoom = null;
    _roomPlayers = [];
    _currentAuction = null;
    _currentRoomPlayer = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }
}
