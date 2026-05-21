import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ipl_auction_game/core/constants/app_constants.dart';
import 'package:ipl_auction_game/models/room_model.dart';
import 'package:ipl_auction_game/providers/app_providers.dart';
import 'package:ipl_auction_game/providers/session_controller.dart';

class RoomController extends StateNotifier<AsyncValue<RoomModel?>> {
  RoomController(this._ref) : super(const AsyncData(null));

  final Ref _ref;
  StreamSubscription<RoomModel?>? _roomSub;

  Future<String?> createLobby({required int maxPlayers}) async {
    final session = _ref.read(sessionControllerProvider);
    if (session.uid == null || session.user == null) {
      return 'Complete signup before creating a lobby';
    }
    if (!await _hasActiveSession()) {
      return 'Session expired. Please sign in again.';
    }
    if (maxPlayers < 2) {
      return 'Select at least 2 players';
    }

    state = const AsyncLoading();
    try {
      final room = await _ref.read(databaseServiceProvider).createRoom(
            hostId: session.uid!,
            hostName: session.user!.username,
            maxPlayers: maxPlayers,
          );
      await _ref.read(cacheServiceProvider).cacheLastRoom(room.roomId);
      await watchRoom(room.roomId);
      return null;
    } catch (e, st) {
      state = AsyncError(e, st);
      return _friendlyLobbyError(e);
    }
  }

  Future<String?> joinLobby(String roomCode) async {
    final session = _ref.read(sessionControllerProvider);
    if (session.uid == null || session.user == null) {
      return 'Complete signup before joining a lobby';
    }
    if (!await _hasActiveSession()) {
      return 'Session expired. Please sign in again.';
    }

    state = const AsyncLoading();
    try {
      final db = _ref.read(databaseServiceProvider);
      final room = await db.getRoomByCode(roomCode);
      if (room == null) {
        throw Exception('Room not found');
      }

      // Use actual room-player entries to avoid stale playerCount mismatch.
      final currentPlayers = await db.getRoomPlayers(room.roomId);
      if (currentPlayers.length >= room.maxPlayers) {
        throw Exception('Room is full');
      }

      await db.addRoomPlayer(
        roomId: room.roomId,
        userId: session.uid!,
        username: session.user!.username,
        hostId: room.hostId,
      );
      await _ref.read(cacheServiceProvider).cacheLastRoom(room.roomId);
      await watchRoom(room.roomId);
      return null;
    } catch (e, st) {
      state = AsyncError(e, st);
      return _friendlyLobbyError(e);
    }
  }

  Future<bool> _hasActiveSession() async {
    final account = await _ref.read(authServiceProvider).getCurrentUserOrNull();
    return account != null;
  }

  String _friendlyLobbyError(Object error) {
    if (error is AppwriteException) {
      final message = (error.message ?? '').toLowerCase();

      if (error.code == 401) {
        return 'Session expired. Please sign in again.';
      }

      if (kIsWeb &&
          (message.contains('origin') ||
              message.contains('platform') ||
              message.contains('cookie') ||
              message.contains('cors'))) {
        return 'Web platform is not fully configured in Appwrite. Add your Chrome debug URL to Appwrite Platforms and allow cookies.';
      }

      return error.message ?? error.toString();
    }
    return error.toString();
  }

  Future<void> watchRoom(String roomId) async {
    await _roomSub?.cancel();
    final db = _ref.read(databaseServiceProvider);
    final current = await db.getRoom(roomId);
    state = AsyncData(current);

    if (current == null) {
      return;
    }

    final stream = _ref.read(realtimeServiceProvider).subscribeToRoom(roomId);
    _roomSub = stream.listen((room) {
      state = AsyncData(room);
      if (room == null) {
        _roomSub?.cancel();
      }
    });
  }

  Future<void> assignTeams() async {
    final room = state.value;
    if (room == null) {
      return;
    }
    await _ref.read(databaseServiceProvider).assignTeamsRandomly(room);
  }

  Future<String?> startAuction(List<String>? playerIds) async {
    final room = state.value;
    if (room == null) {
      return 'Room unavailable';
    }

    final db = _ref.read(databaseServiceProvider);
    final players = await db.getRoomPlayers(room.roomId);
    
    // Use all players who have selected teams (auto-marked as ready)
    final readyPlayers = players.where((player) => player.isReady).toList()
      ..sort((a, b) {
        final aJoined = a.joinedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bJoined = b.joinedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return aJoined.compareTo(bJoined);
      });
    
    final assignedPlayers = readyPlayers.where((player) => player.teamName != null && player.teamName!.isNotEmpty).toList();

    if (readyPlayers.isEmpty) {
      return 'No players have selected teams yet';
    }
    if (assignedPlayers.length != readyPlayers.length) {
      return 'All players must select a team before starting';
    }
    final uniqueTeams = assignedPlayers.map((player) => player.teamName!).toSet();
    if (uniqueTeams.length != readyPlayers.length) {
      return 'Each player must have a unique team';
    }

    final order = readyPlayers.map((player) => player.userId).toList();
    final firstPlayer = order.isNotEmpty ? order.first : null;

    try {
      await db.createAuction(
        roomId: room.roomId,
      );

      await db.updateRoom(
        room.copyWith(status: RoomStatus.inAuction),
      );
      await db.updateRoomFields(room.roomId, {
        'currentOrder': order,
        'currentPlayer': firstPlayer,
        'highestBid': 0,
        'timer': AppConstants.initialAuctionTimer,
      });
      return null;
    } catch (e, st) {
      print('Failed to start auction: $e');
      print(st);
      return e.toString();
    }
  }

  Future<String?> leaveRoom() async {
    final session = _ref.read(sessionControllerProvider);
    final room = state.value;
    if (session.uid == null || room == null) {
      return null;
    }

    try {
      final db = _ref.read(databaseServiceProvider);
      final players = await db.getRoomPlayers(room.roomId);
      final current = players.where((player) => player.userId == session.uid).toList();

      if (current.isNotEmpty) {
        final remaining = players.where((player) => player.userId != session.uid).toList()
          ..sort((a, b) {
            final aJoined = a.joinedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bJoined = b.joinedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return aJoined.compareTo(bJoined);
          });

        if (room.hostId == session.uid && remaining.isNotEmpty) {
          final newHost = remaining.first;
          await db.transferHost(
            roomId: room.roomId,
            newHostId: newHost.userId,
            newHostName: newHost.username,
          );
        }

        await db.deleteRoomPlayer(roomId: room.roomId, userId: session.uid!);
      }

      await _roomSub?.cancel();
      state = const AsyncData(null);
      return null;
    } catch (e, st) {
      state = AsyncError(e, st);
      return e.toString();
    }
  }

  Future<String?> deleteRoom() async {
    final session = _ref.read(sessionControllerProvider);
    final room = state.value;
    if (session.uid == null || room == null) {
      return null;
    }
    if (room.hostId != session.uid) {
      return 'Only the host can delete the room';
    }

    try {
      final db = _ref.read(databaseServiceProvider);
      await db.deleteRoom(room.roomId);
      await _roomSub?.cancel();
      state = const AsyncData(null);
      return null;
    } catch (e, st) {
      state = AsyncError(e, st);
      return e.toString();
    }
  }

  Future<void> tickTimer() async {
    final room = state.value;
    if (room == null) {
      return;
    }
    final newTimer = (room.timer - 1).clamp(0, double.infinity).toInt();
    state = AsyncData(room.copyWith(timer: newTimer));
  }

  Future<void> placeBid(int amount) async {
    final room = state.value;
    if (room == null) {
      return;
    }
    final session = _ref.read(sessionControllerProvider);
    final db = _ref.read(databaseServiceProvider);
    final functions = _ref.read(functionServiceProvider);

    try {
      // Get current auction
      final auction = await db.getAuctionForRoom(room.roomId);
      if (auction == null || session.uid == null || session.user == null) {
        throw Exception('Auction or session data missing');
      }

      // Call server-side validation function for atomicity
      final result = await functions.placeBid(
        roomId: room.roomId,
        bidAmount: amount,
        userId: session.uid!,
        username: session.user!.username,
        playerName: room.currentPlayer ?? '',
        auctionId: auction.id,
      );

      // Update local state optimistically based on server response
      state = AsyncData(room.copyWith(
        highestBid: (result['highestBid'] as num).toInt(),
        timer: AppConstants.initialAuctionTimer,
      ));
    } catch (e, st) {
      print('Error placing bid: $e');
      print(st);
      state = AsyncError(e, st);
    }
  }

  Future<void> nextPlayer({required bool sold}) async {
    final room = state.value;
    if (room == null) {
      return;
    }

    final db = _ref.read(databaseServiceProvider);
    var order = List<String>.from(room.currentOrder);
    if (order.isEmpty || !order.contains(room.currentPlayer)) {
      final players = await db.getRoomPlayers(room.roomId);
      final approvedPlayers = players.where((player) => player.isReady).toList()
        ..sort((a, b) {
          final aJoined = a.joinedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bJoined = b.joinedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return aJoined.compareTo(bJoined);
        });
      order = approvedPlayers.map((player) => player.userId).toList();
    }

    final currentIndex = order.indexOf(room.currentPlayer ?? '');
    final nextIndex = currentIndex + 1;
    if (nextIndex < order.length) {
      final nextPlayer = order[nextIndex];
      try {
        await db.updateRoomFields(room.roomId, {
          'currentOrder': order,
          'currentPlayer': nextPlayer,
          'highestBid': 0,
          'timer': AppConstants.initialAuctionTimer,
        });
      } catch (_) {
        // ignore persistence failures here - we'll still update local state
      }

      state = AsyncData(room.copyWith(
        currentOrder: order,
        currentPlayer: nextPlayer,
        highestBid: 0,
        timer: 60,
      ));
    } else {
      // Keep the room active here. The auction screen controls auction
      // completion based on the loaded player list, not the room participant list.
      try {
        await db.updateRoomFields(room.roomId, {
          'currentOrder': order,
          'highestBid': 0,
          'timer': AppConstants.initialAuctionTimer,
        });
      } catch (_) {
        // ignore persistence failures here - we'll still update local state
      }

      state = AsyncData(room.copyWith(
        currentOrder: order,
        highestBid: 0,
        timer: 60,
      ));
    }
  }

  Future<void> approve(String uid, bool approved) async {
    final room = state.value;
    if (room == null) {
      return;
    }
    // Update player approval status
    await _ref.read(databaseServiceProvider).updateRoomPlayer(
      roomId: room.roomId,
      userId: uid,
      isReady: approved,
    );
  }

  Future<void> updateRoomStatus(RoomStatus status) async {
    final room = state.value;
    if (room == null) {
      return;
    }
    await _ref.read(databaseServiceProvider).updateRoom(
      room.copyWith(status: status),
    );
  }

  Future<void> updatePlayerReady(String userId, bool isReady) async {
    final room = state.value;
    if (room == null) {
      return;
    }
    await _ref.read(databaseServiceProvider).updateRoomPlayer(
      roomId: room.roomId,
      userId: userId,
      isReady: isReady,
    );
  }

  @override
  void dispose() {
    _roomSub?.cancel();
    super.dispose();
  }
}

final roomControllerProvider =
    StateNotifierProvider<RoomController, AsyncValue<RoomModel?>>((ref) {
  return RoomController(ref);
});

final isHostProvider = Provider<bool>((ref) {
  final room = ref.watch(roomControllerProvider).value;
  final uid = ref.watch(sessionControllerProvider.select((s) => s.uid));
  return room != null && uid != null && room.hostId == uid;
});
