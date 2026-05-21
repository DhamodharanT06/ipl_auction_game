import 'package:appwrite/appwrite.dart';

// Appwrite Configuration
class AppwriteConfig {
  // Replace these with your actual Appwrite project details
  static const String endpoint = 'https://nyc.cloud.appwrite.io/v1'; // Your Appwrite endpoint
  static const String projectId = '69e70398003c632edda2'; // Your project ID from Appwrite console
  static const String databaseId = 'ipl_auction_users'; // Your database ID
  
  // Collection IDs (exact from Appwrite schema)
  static const String usersCollection = 'users';
  static const String roomsCollection = 'rooms';
  static const String roomPlayersCollection = 'roomPlayers';
  static const String auctionsCollection = 'auctions';
  static const String bidsCollection = 'bids';
  static const String playersCollection = 'players';
  static const String teamsCollection = 'teams'; // For future use
  
  // Storage bucket ID
  static const String avatarsBucket = 'avatars';
  
  // Get configured Appwrite client
  static Client get client {
    return Client()
      .setEndpoint(endpoint)
      .setProject(projectId)
      .setSelfSigned(status: true); // Remove in production
  }
}

// class Environment {
//   static const String appwriteProjectId = '69e70398003c632edda2';
//   static const String appwriteProjectName = 'IPL auction game';
//   static const String appwritePublicEndpoint = 'https://nyc.cloud.appwrite.io/v1';
// }