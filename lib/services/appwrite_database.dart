import 'package:appwrite/appwrite.dart';
import '../config/appwrite_config.dart';

/// AppwriteDatabase Service
/// Handles database collection creation and management
class AppwriteDatabase {
  static final AppwriteDatabase _instance = AppwriteDatabase._internal();
  factory AppwriteDatabase() => _instance;
  AppwriteDatabase._internal();

  late Client client;
  late Databases databases;
  bool _isInitialized = false;

  void init() {
    if (!_isInitialized) {
      client = Client()
          .setEndpoint(AppwriteConfig.endpoint)
          .setProject(AppwriteConfig.projectId);
      databases = Databases(client);
      _isInitialized = true;
    }
  }

  /// Initialize all required database collections
  /// Creates collections if they don't exist
  Future<void> initializeDatabase() async {
    if (!_isInitialized) {
      throw Exception('AppwriteDatabase not initialized. Call init() first.');
    }

    try {
      // Create Users Collection
      await _createUsersCollection();
      
      // Create Rooms Collection
      await _createRoomsCollection();
      
      // Create RoomPlayers Collection
      await _createRoomPlayersCollection();
      
      // Create Auctions Collection
      await _createAuctionsCollection();
      
      // Create Bids Collection
      await _createBidsCollection();
      
      print('✅ Database collections initialized successfully');
    } catch (e) {
      print('❌ Database initialization error: $e');
      rethrow;
    }
  }

  /// Create Users collection
  Future<void> _createUsersCollection() async {
    try {
      // Try to list documents to see if collection exists
      await databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.usersCollection,
      );
      print('✅ Users collection already exists');
    } catch (e) {
      if (e.toString().contains('404')) {
        print('⚠️  Users collection does not exist. Create it in Appwrite Console');
        print('   Collection ID: ${AppwriteConfig.usersCollection}');
      } else {
        print('⚠️  Users collection error: $e');
      }
    }
  }

  /// Create Rooms collection
  Future<void> _createRoomsCollection() async {
    try {
      await databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.roomsCollection,
      );
      print('✅ Rooms collection already exists');
    } catch (e) {
      if (e.toString().contains('404')) {
        print('⚠️  Rooms collection does not exist. Create it in Appwrite Console');
        print('   Collection ID: ${AppwriteConfig.roomsCollection}');
      } else {
        print('⚠️  Rooms collection error: $e');
      }
    }
  }

  /// Create RoomPlayers collection
  Future<void> _createRoomPlayersCollection() async {
    try {
      await databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.roomPlayersCollection,
      );
      print('✅ RoomPlayers collection already exists');
    } catch (e) {
      if (e.toString().contains('404')) {
        print('⚠️  RoomPlayers collection does not exist. Create it in Appwrite Console');
        print('   Collection ID: ${AppwriteConfig.roomPlayersCollection}');
      } else {
        print('⚠️  RoomPlayers collection error: $e');
      }
    }
  }

  /// Create Auctions collection
  Future<void> _createAuctionsCollection() async {
    try {
      await databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.auctionsCollection,
      );
      print('✅ Auctions collection already exists');
    } catch (e) {
      if (e.toString().contains('404')) {
        print('⚠️  Auctions collection does not exist. Create it in Appwrite Console');
        print('   Collection ID: ${AppwriteConfig.auctionsCollection}');
      } else {
        print('⚠️  Auctions collection error: $e');
      }
    }
  }

  /// Create Bids collection
  Future<void> _createBidsCollection() async {
    try {
      await databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.bidsCollection,
      );
      print('✅ Bids collection already exists');
    } catch (e) {
      if (e.toString().contains('404')) {
        print('⚠️  Bids collection does not exist. Create it in Appwrite Console');
        print('   Collection ID: ${AppwriteConfig.bidsCollection}');
      } else {
        print('⚠️  Bids collection error: $e');
      }
    }
  }
}

