import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import '../config/appwrite_config.dart';

class AppwriteService {
  static final AppwriteService _instance = AppwriteService._internal();
  factory AppwriteService() => _instance;
  AppwriteService._internal();

  late Client client;
  late Account account;
  late Databases databases;
  late Realtime realtime;
  late Storage storage;

  void init() {
    client = Client()
        .setEndpoint(AppwriteConfig.endpoint)
        .setProject(AppwriteConfig.projectId);

    account = Account(client);
    databases = Databases(client);
    realtime = Realtime(client);
    storage = Storage(client);
  }

  // Auth Methods
  Future<models.User> getCurrentUser() async {
    try {
      return await account.get();
    } catch (e) {
      rethrow;
    }
  }

  Future<models.Session> login(String email, String password) async {
    try {
      return await account.createEmailPasswordSession(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<models.User> register(
      String email, String password, String name) async {
    try {
      return await account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<models.User> createAnonymousSession() async {
    try {
      await account.createAnonymousSession();
      return await account.get();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await account.deleteSession(sessionId: 'current');
    } catch (e) {
      rethrow;
    }
  }

  // User Profile Methods
  Future<models.Document> createUserProfile({
    required String userId,
    required String username,
    String? avatarUrl,
  }) async {
    try {
      return await databases.createDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.usersCollection,
        documentId: userId,
        data: {
          'username': username,
          'avatarUrl': avatarUrl ?? '',
          'matchesPlayed': 0,
          'matchesWon': 0,
          'totalCoins': 0,
          'badges': [],
          'soundEnabled': true,
          'darkModeEnabled': false,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<models.Document> getUserProfile(String userId) async {
    try {
      return await databases.getDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.usersCollection,
        documentId: userId,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<models.Document> updateUserProfile(
      String userId, Map<String, dynamic> data) async {
    try {
      return await databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.usersCollection,
        documentId: userId,
        data: data,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Room Methods
  Future<models.Document> createRoom({
    required String roomCode,
    required String hostId,
    required String hostName,
  }) async {
    try {
      return await databases.createDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.roomsCollection,
        documentId: ID.unique(),
        data: {
          'roomCode': roomCode,
          'hostId': hostId,
          'hostName': hostName,
          'status': 'waiting',
          'maxPlayers': 2,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<models.DocumentList> getRoomByCode(String roomCode) async {
    try {
      return await databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.roomsCollection,
        queries: [
          Query.equal('roomCode', roomCode),
        ],
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<models.Document> updateRoom(
      String roomId, Map<String, dynamic> data) async {
    try {
      return await databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.roomsCollection,
        documentId: roomId,
        data: data,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Room Player Methods
  Future<models.Document> addPlayerToRoom({
    required String roomId,
    required String userId,
    required String username,
  }) async {
    try {
      return await databases.createDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.roomPlayersCollection,
        documentId: ID.unique(),
        data: {
          'roomId': roomId,
          'userId': userId,
          'username': username,
          'isReady': false,
          'isHost': false,
          'teamName': null,
          'budget': 1000,
          'joinedAt': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<models.DocumentList> getRoomPlayers(String roomId) async {
    try {
      return await databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.roomPlayersCollection,
        queries: [
          Query.equal('roomId', roomId),
        ],
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<models.Document> updateRoomPlayer(
      String playerId, Map<String, dynamic> data) async {
    try {
      return await databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.roomPlayersCollection,
        documentId: playerId,
        data: data,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removePlayerFromRoom(String playerId) async {
    try {
      await databases.deleteDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.roomPlayersCollection,
        documentId: playerId,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Auction Methods
  Future<models.Document> createAuction({
    required String roomId,
    required List<Map<String, dynamic>> players,
  }) async {
    try {
      return await databases.createDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.auctionsCollection,
        documentId: ID.unique(),
        data: {
          'roomId': roomId,
          'currentPlayerIndex': 0,
          'currentBid': 0,
          'currentBidder': null,
          'currentBidderTeam': null,
          'status': 'active',
          'startedAt': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<models.Document> getAuction(String roomId) async {
    try {
      final result = await databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.auctionsCollection,
        queries: [
          Query.equal('roomId', roomId),
        ],
      );
      return result.documents.first;
    } catch (e) {
      rethrow;
    }
  }

  Future<models.Document> updateAuction(
      String auctionId, Map<String, dynamic> data) async {
    try {
      return await databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.auctionsCollection,
        documentId: auctionId,
        data: data,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Bid Methods
  Future<models.Document> createBid({
    required String auctionId,
    required String userId,
    required String username,
    required int bidAmount,
    required String playerName,
  }) async {
    try {
      return await databases.createDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.bidsCollection,
        documentId: ID.unique(),
        data: {
          'auctionId': auctionId,
          'userId': userId,
          'username': username,
          'bidAmount': bidAmount,
          'playerName': playerName,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  // Realtime Subscriptions
  void subscribeToRoom(
      String roomId, Function(RealtimeMessage) callback) {
    realtime.subscribe([
      'databases.${AppwriteConfig.databaseId}.collections.${AppwriteConfig.roomsCollection}.documents.$roomId'
    ]).stream.listen(callback);
  }

  void subscribeToRoomPlayers(
      String roomId, Function(RealtimeMessage) callback) {
    realtime.subscribe([
      'databases.${AppwriteConfig.databaseId}.collections.${AppwriteConfig.roomPlayersCollection}.documents'
    ]).stream.listen(callback);
  }

  void subscribeToAuction(
      String auctionId, Function(RealtimeMessage) callback) {
    realtime.subscribe([
      'databases.${AppwriteConfig.databaseId}.collections.${AppwriteConfig.auctionsCollection}.documents.$auctionId'
    ]).stream.listen(callback);
  }

  // Storage Methods
  Future<models.File> uploadAvatar(String userId, String filePath) async {
    try {
      return await storage.createFile(
        bucketId: AppwriteConfig.avatarsBucket,
        fileId: ID.unique(),
        file: InputFile.fromPath(path: filePath, filename: 'avatar_$userId.jpg'),
      );
    } catch (e) {
      rethrow;
    }
  }

  String getAvatarUrl(String fileId) {
    return '${AppwriteConfig.endpoint}/storage/buckets/${AppwriteConfig.avatarsBucket}/files/$fileId/view?project=${AppwriteConfig.projectId}';
  }
}
