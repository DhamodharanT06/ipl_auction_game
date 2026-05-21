import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:ipl_auction_game/core/config/sheets_env.dart';
import 'package:ipl_auction_game/models/player_model.dart';
import 'package:ipl_auction_game/services/cache_service.dart';
import 'package:ipl_auction_game/services/database_service.dart';
import 'package:ipl_auction_game/services/sheets_service.dart';

class PlayerSheetService {
  PlayerSheetService(this._cacheService);

  final CacheService _cacheService;

  Future<List<PlayerModel>> loadPlayers({bool refresh = true}) async {
    final cached = _cacheService.readPlayers().map(PlayerModel.fromMap).toList();
    if (!refresh) {
      return cached;
    }

    try {
      final response = await http.get(Uri.parse(SheetsEnv.appsScriptEndpoint));
      if (response.statusCode != 200) {
        // Fallback to CSV export if apps script not available
        return await fetchPlayersFromSheet(SheetsEnv.csvExportUrl);
      }

      final body = jsonDecode(response.body);
      final list = (body is List ? body : body['players'] as List?) ?? [];
      final maps = list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      final players = maps.map(PlayerModel.fromMap).toList();
      await _cacheService.cachePlayers(maps);
      return players;
    } catch (_) {
      // Try CSV fallback when Apps Script call fails
      try {
        return await fetchPlayersFromSheet(SheetsEnv.csvExportUrl);
      } catch (_) {
        return cached;
      }
    }
  }

  /// Fetch players from the sheet (using CSV fallback) and create/update
  /// each player in the Appwrite `players` collection via [db].
  Future<int> importPlayersToDb(DatabaseService db, {bool refresh = true}) async {
    final players = await loadPlayers(refresh: refresh);
    var imported = 0;
    for (final p in players) {
      try {
        await db.createOrUpdatePlayer(p);
        imported += 1;
      } catch (_) {
        // ignore single row failures but continue importing
      }
    }
    return imported;
  }
}
