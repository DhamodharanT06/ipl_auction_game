import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:ipl_auction_game/core/config/appwrite_env.dart';
import 'package:ipl_auction_game/models/room_model.dart';
import 'package:ipl_auction_game/models/room_player_model.dart';

class RealtimeService {
  RealtimeService(this._realtime);

  final Realtime _realtime;
  RealtimeSubscription? _subscription;
  final StreamController<dynamic> _controller = StreamController<dynamic>.broadcast();

  Stream<RoomModel?> subscribeToRoom(String roomId) {
    _subscription?.close();

    _subscription = _realtime.subscribe([
      'databases.${AppwriteEnv.databaseId}.collections.${AppwriteEnv.roomsCollectionId}.documents.$roomId',
    ]);

    _subscription!.stream.listen((event) {
      if (event.events.any((name) => name.contains('.delete'))) {
        _controller.add(null);
        return;
      }

      final payload = Map<String, dynamic>.from(event.payload as Map);
      if (payload.isNotEmpty) {
        _controller.add(RoomModel.fromMap(payload));
      }
    });

    return _controller.stream.cast<RoomModel?>();
  }

  Stream<List<RoomPlayerModel>> subscribeToRoomPlayers(
    String roomId,
    Future<List<RoomPlayerModel>> Function() loadPlayers,
  ) {
    final controller = StreamController<List<RoomPlayerModel>>.broadcast();
    RealtimeSubscription? subscription;

    Future<void> emitPlayers() async {
      try {
        controller.add(await loadPlayers());
      } catch (_) {
        // The next realtime event will retry the refresh.
      }
    }

    subscription = _realtime.subscribe([
      'databases.${AppwriteEnv.databaseId}.collections.${AppwriteEnv.roomPlayersCollectionId}.documents',
    ]);

    subscription.stream.listen((event) {
      final payload = Map<String, dynamic>.from(event.payload as Map);
      final eventRoomId = payload['roomId']?.toString();
      if (eventRoomId != roomId) {
        return;
      }
      emitPlayers();
    });

    emitPlayers();

    controller.onCancel = () async {
      await subscription?.close();
    };

    return controller.stream;
  }

  Stream<List<Map<String, dynamic>>> subscribeToBids(
    String roomId,
    Future<List<Map<String, dynamic>>> Function() loadBids,
  ) {
    final controller = StreamController<List<Map<String, dynamic>>>.broadcast();
    RealtimeSubscription? subscription;
    Timer? debounceTimer;
    bool isLoading = false;

    Future<void> emitBids() async {
      if (isLoading) return;
      isLoading = true;
      try {
        final bidsList = await loadBids();
        if (!controller.isClosed) {
          controller.add(bidsList);
        }
      } catch (_) {
        // The next realtime event will retry the refresh.
      } finally {
        isLoading = false;
      }
    }

    subscription = _realtime.subscribe([
      'databases.${AppwriteEnv.databaseId}.collections.${AppwriteEnv.bidsCollectionId}.documents',
    ]);

    subscription.stream.listen((event) {
      // Quick debounce to prevent excessive queries (100ms is fast enough)
      debounceTimer?.cancel();
      debounceTimer = Timer(const Duration(milliseconds: 100), () {
        emitBids();
      });
    });

    // Initial load
    emitBids();

    controller.onCancel = () async {
      debounceTimer?.cancel();
      await subscription?.close();
    };

    return controller.stream;
  }

  Future<void> close() async {
    await _subscription?.close();
    _subscription = null;
  }

  void dispose() {
    _subscription?.close();
    _controller.close();
  }
}
