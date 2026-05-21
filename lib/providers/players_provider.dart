import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ipl_auction_game/models/player_model.dart';
import 'package:ipl_auction_game/providers/app_providers.dart';

final playersProvider = FutureProvider<List<PlayerModel>>((ref) async {
  final service = ref.watch(playerSheetServiceProvider);
  return service.loadPlayers(refresh: true);
});
