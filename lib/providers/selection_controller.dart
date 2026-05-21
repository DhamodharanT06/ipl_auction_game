import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ipl_auction_game/models/player_model.dart';
import 'package:ipl_auction_game/models/room_model.dart';
import 'package:ipl_auction_game/providers/app_providers.dart';
import 'package:ipl_auction_game/providers/room_controller.dart';
import 'package:ipl_auction_game/providers/session_controller.dart';

class SelectionState {
  const SelectionState({
    this.selected = const <String>{},
    this.captainId,
    this.viceCaptainId,
    this.error,
  });

  final Set<String> selected;
  final String? captainId;
  final String? viceCaptainId;
  final String? error;

  SelectionState copyWith({
    Set<String>? selected,
    String? captainId,
    String? viceCaptainId,
    String? error,
  }) {
    return SelectionState(
      selected: selected ?? this.selected,
      captainId: captainId ?? this.captainId,
      viceCaptainId: viceCaptainId ?? this.viceCaptainId,
      error: error,
    );
  }
}

class SelectionController extends StateNotifier<SelectionState> {
  SelectionController(this._ref) : super(const SelectionState());

  final Ref _ref;

  void togglePlayer(PlayerModel player) {
    final current = {...state.selected};
    if (current.contains(player.playerId)) {
      current.remove(player.playerId);
    } else if (current.length < 11) {
      current.add(player.playerId);
    }
    state = state.copyWith(selected: current, error: null);
  }

  void setCaptain(String id) {
    state = state.copyWith(captainId: id, error: null);
  }

  void setViceCaptain(String id) {
    state = state.copyWith(viceCaptainId: id, error: null);
  }

  String? validate(List<PlayerModel> selectedPlayers) {
    if (selectedPlayers.length != 11) {
      return 'You must pick exactly 11 players';
    }
    final foreign = selectedPlayers.where((p) => p.isForeign).length;
    if (foreign > 4) {
      return 'Maximum 4 foreign players allowed';
    }
    final keepers = selectedPlayers.where((p) => p.isWicketKeeper).length;
    if (keepers < 1) {
      return 'At least 1 wicketkeeper is required';
    }
    if (state.captainId == null || state.viceCaptainId == null) {
      return 'Choose captain and vice captain';
    }
    if (state.captainId == state.viceCaptainId) {
      return 'Captain and vice captain must be different';
    }
    return null;
  }

  Future<bool> submit(List<PlayerModel> allPlayers) async {
    final selectedPlayers = allPlayers
        .where((p) => state.selected.contains(p.playerId))
        .toList();
    final validationError = validate(selectedPlayers);
    if (validationError != null) {
      state = state.copyWith(error: validationError);
      return false;
    }

    final room = _ref.read(roomControllerProvider).value;
    final uid = _ref.read(sessionControllerProvider).uid;
    if (room == null || uid == null) {
      return false;
    }

    // Save player selection to database
    await _ref.read(databaseServiceProvider).savePlayerSelection(
          roomId: room.roomId,
          userId: uid,
          selectedPlayerIds: selectedPlayers.map((e) => e.playerId).toList(),
          captainId: state.captainId!,
          viceCaptainId: state.viceCaptainId!,
        );

    // Mark player as ready
    await _ref.read(roomControllerProvider.notifier)
        .updatePlayerReady(uid, true);
    return true;
  }

  Future<void> calculateAndSaveLeaderboard(List<PlayerModel> allPlayers) async {
    final room = _ref.read(roomControllerProvider).value;
    if (room == null) {
      return;
    }
    
    // Calculate leaderboard based on team selections and auction results
    // This would be implemented based on your business logic
    try {
      await _ref.read(databaseServiceProvider).updateRoom(
        room.copyWith(status: RoomStatus.completed),
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to save leaderboard: $e');
    }
  }
}

final selectionControllerProvider =
    StateNotifierProvider<SelectionController, SelectionState>((ref) {
  return SelectionController(ref);
});
