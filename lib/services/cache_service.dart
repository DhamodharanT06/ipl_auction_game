import 'package:hive_flutter/hive_flutter.dart';

class CacheService {
  static const _playersBox = 'players_cache';
  static const _appBox = 'app_cache';

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_playersBox);
    await Hive.openBox(_appBox);
  }

  Future<void> cachePlayers(List<Map<String, dynamic>> data) async {
    final box = Hive.box(_playersBox);
    await box.put('players', data);
    await box.put('last_sync', DateTime.now().toIso8601String());
  }

  List<Map<String, dynamic>> readPlayers() {
    final box = Hive.box(_playersBox);
    final raw = box.get('players', defaultValue: <dynamic>[]) as List<dynamic>;
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> cacheLastRoom(String roomId) async {
    await Hive.box(_appBox).put('last_room_id', roomId);
  }

  String? readLastRoom() {
    return Hive.box(_appBox).get('last_room_id') as String?;
  }

  Future<void> setAutoSync(bool enabled) async {
    await Hive.box(_appBox).put('auto_sync_players', enabled);
  }

  bool readAutoSync() {
    return Hive.box(_appBox).get('auto_sync_players', defaultValue: false) as bool;
  }
}
