class AppwriteEnv {
  static const endpoint = 'https://nyc.cloud.appwrite.io/v1';
  static const projectId = '69e70398003c632edda2';
  static const databaseId = 'ipl_auction_users';

  // Table IDs (max 10 chars - exact from Appwrite)
  static const usersCollectionId = 'users';
  static const roomsCollectionId = 'rooms';
  static const roomPlayersCollectionId = 'roomPlayers';
  static const auctionsCollectionId = 'auctions';
  static const bidsCollectionId = 'bids';
  static const playersCollectionId = 'players';
  static const squadsCollectionId = 'squads';

  static const bidFunctionId = 'place_bid';
  static const timerFunctionId = 'auction_timer';
}
