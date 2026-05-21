import 'package:appwrite/appwrite.dart';
import '../config/appwrite_config.dart';

/// Run this once to seed your database with IPL players
/// Call this from a button in settings or run manually
class PlayerSeeder {
  final Databases databases;

  PlayerSeeder(Client client) : databases = Databases(client);

  Future<void> seedPlayers() async {
    final players = [
      // Indian Batsmen
      {'name': 'Virat Kohli', 'role': 'Batsman', 'rating': 95, 'basePrice': 150, 'country': 'India', 'imageUrl': ''},
      {'name': 'Rohit Sharma', 'role': 'Batsman', 'rating': 94, 'basePrice': 140, 'country': 'India', 'imageUrl': ''},
      {'name': 'KL Rahul', 'role': 'Wicket-keeper', 'rating': 89, 'basePrice': 120, 'country': 'India', 'imageUrl': ''},
      {'name': 'Shubman Gill', 'role': 'Batsman', 'rating': 87, 'basePrice': 100, 'country': 'India', 'imageUrl': ''},
      {'name': 'Suryakumar Yadav', 'role': 'Batsman', 'rating': 90, 'basePrice': 110, 'country': 'India', 'imageUrl': ''},
      {'name': 'Sanju Samson', 'role': 'Wicket-keeper', 'rating': 84, 'basePrice': 80, 'country': 'India', 'imageUrl': ''},
      {'name': 'Rishabh Pant', 'role': 'Wicket-keeper', 'rating': 88, 'basePrice': 120, 'country': 'India', 'imageUrl': ''},
      {'name': 'Ishan Kishan', 'role': 'Wicket-keeper', 'rating': 82, 'basePrice': 70, 'country': 'India', 'imageUrl': ''},
      
      // Indian All-rounders
      {'name': 'Hardik Pandya', 'role': 'All-rounder', 'rating': 88, 'basePrice': 120, 'country': 'India', 'imageUrl': ''},
      {'name': 'Ravindra Jadeja', 'role': 'All-rounder', 'rating': 90, 'basePrice': 130, 'country': 'India', 'imageUrl': ''},
      {'name': 'Axar Patel', 'role': 'All-rounder', 'rating': 83, 'basePrice': 70, 'country': 'India', 'imageUrl': ''},
      {'name': 'Shardul Thakur', 'role': 'All-rounder', 'rating': 80, 'basePrice': 60, 'country': 'India', 'imageUrl': ''},
      {'name': 'Washington Sundar', 'role': 'All-rounder', 'rating': 78, 'basePrice': 50, 'country': 'India', 'imageUrl': ''},
      
      // Indian Bowlers
      {'name': 'Jasprit Bumrah', 'role': 'Bowler', 'rating': 96, 'basePrice': 150, 'country': 'India', 'imageUrl': ''},
      {'name': 'Mohammed Shami', 'role': 'Bowler', 'rating': 88, 'basePrice': 100, 'country': 'India', 'imageUrl': ''},
      {'name': 'Mohammed Siraj', 'role': 'Bowler', 'rating': 85, 'basePrice': 80, 'country': 'India', 'imageUrl': ''},
      {'name': 'Yuzvendra Chahal', 'role': 'Bowler', 'rating': 86, 'basePrice': 80, 'country': 'India', 'imageUrl': ''},
      {'name': 'Kuldeep Yadav', 'role': 'Bowler', 'rating': 84, 'basePrice': 70, 'country': 'India', 'imageUrl': ''},
      {'name': 'Arshdeep Singh', 'role': 'Bowler', 'rating': 82, 'basePrice': 60, 'country': 'India', 'imageUrl': ''},
      {'name': 'Bhuvneshwar Kumar', 'role': 'Bowler', 'rating': 83, 'basePrice': 70, 'country': 'India', 'imageUrl': ''},
      
      // Foreign Players - Batsmen
      {'name': 'David Warner', 'role': 'Batsman', 'rating': 91, 'basePrice': 120, 'country': 'Australia', 'imageUrl': ''},
      {'name': 'Jos Buttler', 'role': 'Wicket-keeper', 'rating': 92, 'basePrice': 130, 'country': 'England', 'imageUrl': ''},
      {'name': 'Quinton de Kock', 'role': 'Wicket-keeper', 'rating': 88, 'basePrice': 100, 'country': 'South Africa', 'imageUrl': ''},
      {'name': 'Faf du Plessis', 'role': 'Batsman', 'rating': 86, 'basePrice': 80, 'country': 'South Africa', 'imageUrl': ''},
      {'name': 'Kane Williamson', 'role': 'Batsman', 'rating': 89, 'basePrice': 100, 'country': 'New Zealand', 'imageUrl': ''},
      {'name': 'Devon Conway', 'role': 'Batsman', 'rating': 85, 'basePrice': 70, 'country': 'New Zealand', 'imageUrl': ''},
      {'name': 'Travis Head', 'role': 'Batsman', 'rating': 86, 'basePrice': 80, 'country': 'Australia', 'imageUrl': ''},
      
      // Foreign All-rounders
      {'name': 'Glenn Maxwell', 'role': 'All-rounder', 'rating': 88, 'basePrice': 110, 'country': 'Australia', 'imageUrl': ''},
      {'name': 'Ben Stokes', 'role': 'All-rounder', 'rating': 90, 'basePrice': 130, 'country': 'England', 'imageUrl': ''},
      {'name': 'Marcus Stoinis', 'role': 'All-rounder', 'rating': 84, 'basePrice': 80, 'country': 'Australia', 'imageUrl': ''},
      {'name': 'Sam Curran', 'role': 'All-rounder', 'rating': 85, 'basePrice': 90, 'country': 'England', 'imageUrl': ''},
      {'name': 'Cameron Green', 'role': 'All-rounder', 'rating': 86, 'basePrice': 100, 'country': 'Australia', 'imageUrl': ''},
      {'name': 'Mitchell Marsh', 'role': 'All-rounder', 'rating': 83, 'basePrice': 70, 'country': 'Australia', 'imageUrl': ''},
      
      // Foreign Bowlers
      {'name': 'Rashid Khan', 'role': 'Bowler', 'rating': 91, 'basePrice': 120, 'country': 'Afghanistan', 'imageUrl': ''},
      {'name': 'Trent Boult', 'role': 'Bowler', 'rating': 88, 'basePrice': 100, 'country': 'New Zealand', 'imageUrl': ''},
      {'name': 'Pat Cummins', 'role': 'Bowler', 'rating': 90, 'basePrice': 120, 'country': 'Australia', 'imageUrl': ''},
      {'name': 'Kagiso Rabada', 'role': 'Bowler', 'rating': 89, 'basePrice': 110, 'country': 'South Africa', 'imageUrl': ''},
      {'name': 'Mitchell Starc', 'role': 'Bowler', 'rating': 88, 'basePrice': 100, 'country': 'Australia', 'imageUrl': ''},
      {'name': 'Josh Hazlewood', 'role': 'Bowler', 'rating': 87, 'basePrice': 90, 'country': 'Australia', 'imageUrl': ''},
      {'name': 'Anrich Nortje', 'role': 'Bowler', 'rating': 86, 'basePrice': 80, 'country': 'South Africa', 'imageUrl': ''},
      {'name': 'Lockie Ferguson', 'role': 'Bowler', 'rating': 85, 'basePrice': 70, 'country': 'New Zealand', 'imageUrl': ''},
      {'name': 'Adam Zampa', 'role': 'Bowler', 'rating': 84, 'basePrice': 60, 'country': 'Australia', 'imageUrl': ''},
      
      // More Indian Players
      {'name': 'Shreyas Iyer', 'role': 'Batsman', 'rating': 85, 'basePrice': 90, 'country': 'India', 'imageUrl': ''},
      {'name': 'Devdutt Padikkal', 'role': 'Batsman', 'rating': 80, 'basePrice': 50, 'country': 'India', 'imageUrl': ''},
      {'name': 'Prithvi Shaw', 'role': 'Batsman', 'rating': 79, 'basePrice': 40, 'country': 'India', 'imageUrl': ''},
      {'name': 'Ruturaj Gaikwad', 'role': 'Batsman', 'rating': 84, 'basePrice': 70, 'country': 'India', 'imageUrl': ''},
      {'name': 'Venkatesh Iyer', 'role': 'All-rounder', 'rating': 78, 'basePrice': 50, 'country': 'India', 'imageUrl': ''},
      {'name': 'Deepak Chahar', 'role': 'Bowler', 'rating': 81, 'basePrice': 60, 'country': 'India', 'imageUrl': ''},
      {'name': 'Prasidh Krishna', 'role': 'Bowler', 'rating': 80, 'basePrice': 50, 'country': 'India', 'imageUrl': ''},
      {'name': 'Avesh Khan', 'role': 'Bowler', 'rating': 79, 'basePrice': 40, 'country': 'India', 'imageUrl': ''},
      
      // Legends (for fun)
      {'name': 'MS Dhoni', 'role': 'Wicket-keeper', 'rating': 92, 'basePrice': 150, 'country': 'India', 'imageUrl': ''},
      {'name': 'AB de Villiers', 'role': 'Batsman', 'rating': 94, 'basePrice': 150, 'country': 'South Africa', 'imageUrl': ''},
    ];

    int added = 0;
    int failed = 0;

    for (final player in players) {
      try {
        await databases.createDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.playersCollection,
          documentId: ID.unique(),
          data: player,
        );
        added++;
        print('✓ Added: ${player['name']}');
      } catch (e) {
        failed++;
        print('✗ Failed: ${player['name']} - $e');
      }
    }

    print('\n=============================');
    print('Seeding Complete!');
    print('Added: $added players');
    print('Failed: $failed players');
    print('=============================');
  }

  /// Delete all players (use with caution!)
  Future<void> clearAllPlayers() async {
    try {
      final docs = await databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.playersCollection,
      );

      for (final doc in docs.documents) {
        await databases.deleteDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.playersCollection,
          documentId: doc.$id,
        );
        print('Deleted: ${doc.data['name']}');
      }

      print('All players cleared!');
    } catch (e) {
      print('Error clearing players: $e');
    }
  }
}
