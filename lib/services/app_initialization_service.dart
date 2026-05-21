import 'package:flutter/material.dart';
import 'appwrite_database.dart';
import 'appwrite_data_seeder.dart';
import 'google_oauth_service.dart';

/// AppInitializationService
/// Handles app initialization tasks including database setup and data seeding
class AppInitializationService {
  static final AppInitializationService _instance =
      AppInitializationService._internal();

  factory AppInitializationService() => _instance;
  AppInitializationService._internal();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  /// Initialize all app services
  /// Should be called early in app lifecycle (main.dart or splash screen)
  Future<void> initializeApp() async {
    if (_initialized) {
      print('⚠️  App already initialized');
      return;
    }

    try {
      debugPrint('🚀 Starting app initialization...');

      // Step 1: Initialize Appwrite Database
      debugPrint('📦 Initializing Appwrite Database...');
      final appwriteDatabase = AppwriteDatabase();
      appwriteDatabase.init();
      await appwriteDatabase.initializeDatabase();

      // Step 2: Initialize Data Seeder
      debugPrint('🌱 Initializing Data Seeder...');
      final dataSeeder = AppwriteDataSeeder();
      dataSeeder.init();
      await dataSeeder.ensurePlayersCollection();
      // Uncomment to seed test data:
      // await dataSeeder.seedPlayers();
      // await dataSeeder.seedTestUsers();

      // Step 3: Initialize Google OAuth Service
      debugPrint('🔐 Initializing Google OAuth...');
      final googleOAuth = GoogleOAuthService();
      googleOAuth.init();

      _initialized = true;
      debugPrint('✅ App initialization completed successfully!');
    } catch (e) {
      debugPrint('❌ App initialization error: $e');
      rethrow;
    }
  }

  /// Reinitialize services if needed (e.g., after network reconnection)
  Future<void> reinitialize() async {
    _initialized = false;
    await initializeApp();
  }
}
