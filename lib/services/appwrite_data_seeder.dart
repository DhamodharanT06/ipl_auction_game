import 'package:appwrite/appwrite.dart';
import '../config/appwrite_config.dart';

/// AppwriteDataSeeder
/// Seeds the database with initial player data and test data
class AppwriteDataSeeder {
  static final AppwriteDataSeeder _instance = AppwriteDataSeeder._internal();
  factory AppwriteDataSeeder() => _instance;
  AppwriteDataSeeder._internal();

  late Client client;
  late Databases databases;

  void init() {
    client = Client()
        .setEndpoint(AppwriteConfig.endpoint)
        .setProject(AppwriteConfig.projectId);
    databases = Databases(client);
  }

  /// Seed database with initial player data
  /// Creates player records for auction
  Future<void> seedPlayers() async {
    try {
      // Sample players data - 50 IPL players
      final players = _generatePlayersList();
      
      print('🌱 Seeding ${players.length} players...');
      
      for (final player in players) {
        try {
          await databases.createDocument(
            databaseId: AppwriteConfig.databaseId,
            collectionId: 'players', // New collection
            documentId: ID.unique(),
            data: player,
          );
        } catch (e) {
          if (!e.toString().contains('already exists')) {
            print('⚠️  Error seeding player: $e');
          }
        }
      }
      
      print('✅ Players seeding completed');
    } catch (e) {
      print('❌ Error in seedPlayers: $e');
      rethrow;
    }
  }

  /// Generate list of 50 IPL players
  List<Map<String, dynamic>> _generatePlayersList() {
    return [
      // BATSMEN (15)
      {'name': 'Virat Kohli', 'role': 'Batsman', 'avgScore': 95, 'isForeign': false, 'basePrice': 20},
      {'name': 'Rohit Sharma', 'role': 'Batsman', 'avgScore': 94, 'isForeign': false, 'basePrice': 20},
      {'name': 'KL Rahul', 'role': 'Batsman', 'avgScore': 89, 'isForeign': false, 'basePrice': 15},
      {'name': 'Suryakumar Yadav', 'role': 'Batsman', 'avgScore': 88, 'isForeign': false, 'basePrice': 14},
      {'name': 'Rishabh Pant', 'role': 'Batsman', 'avgScore': 88, 'isForeign': false, 'basePrice': 15},
      {'name': 'Hardik Pandya', 'role': 'Batsman', 'avgScore': 85, 'isForeign': false, 'basePrice': 12},
      {'name': 'Ishan Kishan', 'role': 'Batsman', 'avgScore': 84, 'isForeign': false, 'basePrice': 11},
      {'name': 'Shreyas Iyer', 'role': 'Batsman', 'avgScore': 83, 'isForeign': false, 'basePrice': 10},
      {'name': 'Agarwal Mayank', 'role': 'Batsman', 'avgScore': 82, 'isForeign': false, 'basePrice': 9},
      {'name': 'Manish Pandey', 'role': 'Batsman', 'avgScore': 80, 'isForeign': false, 'basePrice': 8},
      {'name': 'David Warner', 'role': 'Batsman', 'avgScore': 91, 'isForeign': true, 'basePrice': 17},
      {'name': 'AB de Villiers', 'role': 'Batsman', 'avgScore': 94, 'isForeign': true, 'basePrice': 18},
      {'name': 'Glenn Maxwell', 'role': 'Batsman', 'avgScore': 88, 'isForeign': true, 'basePrice': 14},
      {'name': 'Jos Buttler', 'role': 'Batsman', 'avgScore': 92, 'isForeign': true, 'basePrice': 16},
      {'name': 'Sam Curran', 'role': 'Batsman', 'avgScore': 86, 'isForeign': true, 'basePrice': 12},
      
      // BOWLERS (18)
      {'name': 'Jasprit Bumrah', 'role': 'Bowler', 'avgScore': 96, 'isForeign': false, 'basePrice': 20},
      {'name': 'Ravindra Jadeja', 'role': 'Bowler', 'avgScore': 90, 'isForeign': false, 'basePrice': 16},
      {'name': 'Yuzvendra Chahal', 'role': 'Bowler', 'avgScore': 87, 'isForeign': false, 'basePrice': 13},
      {'name': 'Mohammed Shami', 'role': 'Bowler', 'avgScore': 88, 'isForeign': false, 'basePrice': 14},
      {'name': 'Bhuvneshwar Kumar', 'role': 'Bowler', 'avgScore': 85, 'isForeign': false, 'basePrice': 11},
      {'name': 'Deepak Chahar', 'role': 'Bowler', 'avgScore': 84, 'isForeign': false, 'basePrice': 10},
      {'name': 'Kuldeep Yadav', 'role': 'Bowler', 'avgScore': 83, 'isForeign': false, 'basePrice': 9},
      {'name': 'Umesh Yadav', 'role': 'Bowler', 'avgScore': 82, 'isForeign': false, 'basePrice': 8},
      {'name': 'Prasidh Krishna', 'role': 'Bowler', 'avgScore': 81, 'isForeign': false, 'basePrice': 7},
      {'name': 'Mohammed Siraj', 'role': 'Bowler', 'avgScore': 80, 'isForeign': false, 'basePrice': 6},
      {'name': 'Rashid Khan', 'role': 'Bowler', 'avgScore': 91, 'isForeign': true, 'basePrice': 15},
      {'name': 'Pat Cummins', 'role': 'Bowler', 'avgScore': 90, 'isForeign': true, 'basePrice': 14},
      {'name': 'Kagiso Rabada', 'role': 'Bowler', 'avgScore': 89, 'isForeign': true, 'basePrice': 13},
      {'name': 'Trent Boult', 'role': 'Bowler', 'avgScore': 88, 'isForeign': true, 'basePrice': 12},
      {'name': 'Mitchell Starc', 'role': 'Bowler', 'avgScore': 87, 'isForeign': true, 'basePrice': 11},
      {'name': 'Jason Holder', 'role': 'Bowler', 'avgScore': 85, 'isForeign': true, 'basePrice': 9},
      {'name': 'Mark Wood', 'role': 'Bowler', 'avgScore': 84, 'isForeign': true, 'basePrice': 8},
      {'name': 'Anrich Nortje', 'role': 'Bowler', 'avgScore': 83, 'isForeign': true, 'basePrice': 7},
      
      // ALL-ROUNDERS (10)
      {'name': 'MS Dhoni', 'role': 'All-rounder', 'avgScore': 92, 'isForeign': false, 'basePrice': 18},
      {'name': 'Ben Stokes', 'role': 'All-rounder', 'avgScore': 90, 'isForeign': true, 'basePrice': 16},
      {'name': 'Shakib Al Hasan', 'role': 'All-rounder', 'avgScore': 88, 'isForeign': true, 'basePrice': 14},
      {'name': 'Krunal Pandya', 'role': 'All-rounder', 'avgScore': 82, 'isForeign': false, 'basePrice': 8},
      {'name': 'Washington Sundar', 'role': 'All-rounder', 'avgScore': 80, 'isForeign': false, 'basePrice': 6},
      {'name': 'Chris Gayle', 'role': 'All-rounder', 'avgScore': 91, 'isForeign': true, 'basePrice': 15},
      {'name': 'Moeen Ali', 'role': 'All-rounder', 'avgScore': 86, 'isForeign': true, 'basePrice': 10},
      {'name': 'Marcus Stoinis', 'role': 'All-rounder', 'avgScore': 84, 'isForeign': true, 'basePrice': 9},
      {'name': 'Axar Patel', 'role': 'All-rounder', 'avgScore': 81, 'isForeign': false, 'basePrice': 7},
      {'name': 'Wanindu Hasaranga', 'role': 'All-rounder', 'avgScore': 79, 'isForeign': true, 'basePrice': 5},
      
      // WICKET-KEEPERS (7)
      {'name': 'Wriddhiman Saha', 'role': 'Wicket-keeper', 'avgScore': 85, 'isForeign': false, 'basePrice': 10},
      {'name': 'Dinesh Karthik', 'role': 'Wicket-keeper', 'avgScore': 83, 'isForeign': false, 'basePrice': 8},
      {'name': 'Sanju Samson', 'role': 'Wicket-keeper', 'avgScore': 82, 'isForeign': false, 'basePrice': 7},
      {'name': 'Kieron Pollard', 'role': 'Wicket-keeper', 'avgScore': 81, 'isForeign': true, 'basePrice': 6},
      {'name': 'Nicholas Pooran', 'role': 'Wicket-keeper', 'avgScore': 80, 'isForeign': true, 'basePrice': 5},
      {'name': 'Ramdin Denesh', 'role': 'Wicket-keeper', 'avgScore': 78, 'isForeign': true, 'basePrice': 4},
      {'name': 'Pant Rishabh', 'role': 'Wicket-keeper', 'avgScore': 88, 'isForeign': false, 'basePrice': 12},
    ];
  }

  /// Create Players collection if it doesn't exist
  Future<void> ensurePlayersCollection() async {
    try {
      await databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: 'players',
      );
      print('✅ Players collection already exists');
    } catch (e) {
      if (e.toString().contains('404')) {
        print('⚠️  Players collection does not exist. Create it in Appwrite Console');
        print('   Collection ID: players');
      } else {
        print('⚠️  Players collection error: $e');
      }
    }
  }

  /// Seed test user data
  Future<void> seedTestUsers() async {
    try {
      final testUsers = [
        {
          'username': 'testuser1',
          'email': 'test1@example.com',
          'matchesPlayed': 5,
          'matchesWon': 2,
          'totalCoins': 100,
        },
        {
          'username': 'testuser2',
          'email': 'test2@example.com',
          'matchesPlayed': 8,
          'matchesWon': 4,
          'totalCoins': 250,
        },
        {
          'username': 'testuser3',
          'email': 'test3@example.com',
          'matchesPlayed': 3,
          'matchesWon': 1,
          'totalCoins': 50,
        },
      ];
      
      print('🌱 Seeding ${testUsers.length} test users...');
      
      for (final user in testUsers) {
        try {
          await databases.createDocument(
            databaseId: AppwriteConfig.databaseId,
            collectionId: AppwriteConfig.usersCollection,
            documentId: ID.unique(),
            data: {
              ...user,
              'soundEnabled': true,
              'darkModeEnabled': false,
            },
          );
        } catch (e) {
          if (!e.toString().contains('already exists')) {
            print('⚠️  Error seeding user: $e');
          }
        }
      }
      
      print('✅ Test users seeding completed');
    } catch (e) {
      print('❌ Error in seedTestUsers: $e');
      rethrow;
    }
  }
}
