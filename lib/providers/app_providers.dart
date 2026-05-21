import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ipl_auction_game/services/appwrite_client_service.dart';
import 'package:ipl_auction_game/services/auth_service.dart';
import 'package:ipl_auction_game/services/cache_service.dart';
import 'package:ipl_auction_game/services/database_service.dart';
import 'package:ipl_auction_game/services/function_service.dart';
import 'package:ipl_auction_game/services/player_sheet_service.dart';
import 'package:ipl_auction_game/services/realtime_service.dart';

final appwriteClientProvider = Provider<AppwriteClientService>((ref) {
  return AppwriteClientService();
});

final cacheServiceProvider = Provider<CacheService>((ref) {
  return CacheService();
});

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  final client = ref.watch(appwriteClientProvider);
  return DatabaseService(client.databases);
});

final authServiceProvider = Provider<AuthService>((ref) {
  final client = ref.watch(appwriteClientProvider);
  final db = ref.watch(databaseServiceProvider);
  return AuthService(client.account, db);
});

final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  final client = ref.watch(appwriteClientProvider);
  final service = RealtimeService(client.realtime);
  ref.onDispose(service.dispose);
  return service;
});

final functionServiceProvider = Provider<FunctionService>((ref) {
  final client = ref.watch(appwriteClientProvider);
  return FunctionService(client.functions);
});

final playerSheetServiceProvider = Provider<PlayerSheetService>((ref) {
  final cache = ref.watch(cacheServiceProvider);
  return PlayerSheetService(cache);
});
