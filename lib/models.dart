// Data models for IPL Auction Game

class Player {
  final String name;
  final String role;
  final int avgScore;
  final bool isForeign;
  final String? previousTeam; // For retention logic
  final int? basePrice; // optional base price in lakhs

  // Auction status tracking
  bool isSold = false;
  String? soldToTeam;
  int? soldPrice;

  Player({
    required this.name,
    required this.role,
    required this.avgScore,
    this.isForeign = false,
    this.previousTeam,
    this.basePrice,
  });

  void markAsSold(String teamCode, int price) {
    isSold = true;
    soldToTeam = teamCode;
    soldPrice = price;
  }

  void markAsUnsold() {
    isSold = false;
    soldToTeam = null;
    soldPrice = null;
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'role': role,
      'avgScore': avgScore,
      'isForeign': isForeign,
      'previousTeam': previousTeam,
      'isSold': isSold,
      'soldToTeam': soldToTeam,
      'soldPrice': soldPrice,
      'basePrice': basePrice,
    };
  }
}

class TeamPlayer {
  final String name;
  final int cost;
  final bool isForeign;
  final String role; // Batsman, Bowler, All-rounder, WK-Batsman

  TeamPlayer({
    required this.name,
    required this.cost,
    this.isForeign = false,
    required this.role,
  });
}

class GameTeam {
  final String playerName;
  String teamName; // IPL team name selected
  final bool isHost;
  int totalBudget = 10000; // Starting budget in lakhs (100 Cr)
  int spent = 0;
  List<TeamPlayer> players = [];
  bool hasUsedRetention =
      false; // Track if team has used their one retention chance

  GameTeam({
    required this.playerName,
    required this.teamName,
    this.isHost = false,
  });

  int get remaining => totalBudget - spent;
  int get playersCount => players.length;
  int get foreignPlayersCount => players.where((p) => p.isForeign).length;
  int get wkBatsmanCount =>
      players.where((p) => p.role.toLowerCase().contains('wk')).length;

  bool canBid(int bidAmount) => remaining >= bidAmount;

  bool canAddForeignPlayer() =>
      foreignPlayersCount < 4; // Max 4 foreign players

  bool hasWicketKeeper() =>
      wkBatsmanCount > 0; // Check if team has a WK-Batsman

  bool canAddWicketKeeper() => wkBatsmanCount < 1; // Max 1 WK-Batsman per team

  void addPlayer(String playerName, int cost, bool isForeign, String role) {
    spent += cost;
    players.add(
      TeamPlayer(
        name: playerName,
        cost: cost,
        isForeign: isForeign,
        role: role,
      ),
    );
  }
}

class AuctionState {
  int currentPlayerIndex = 0;
  int highestBid = 0;
  String highestBidder = '';
  String highestBidderTeam = '';
  final List<GameTeam> teams;
  final List<Player> playersToAuction;

  // Auction timing state
  bool isWaitingForBids = false;
  int countdownPhase =
      0; // 0=normal, 1=going once, 2=going twice, 3=sold, 4=retention phase

  // Retention system
  String? retentionRequestTeam; // Team requesting retention
  bool isWaitingForHostApproval = false;
  bool hostApprovedRetention = false;

  AuctionState({required this.teams, required this.playersToAuction});

  Player get currentPlayer => playersToAuction[currentPlayerIndex];
  bool get hasMorePlayers => currentPlayerIndex < playersToAuction.length - 1;

  int getNextBidIncrement(int currentBid) {
    if (currentBid == 0) return 10; // Start at 10L
    if (currentBid < 500) return 10; // +10L for < 5Cr
    if (currentBid < 1000) return 25; // +25L for 5-10Cr
    return 100; // +1Cr for > 10Cr
  }

  void placeBid(String bidderName, String teamName, int bidAmount) {
    highestBid = bidAmount;
    highestBidder = bidderName;
    highestBidderTeam = teamName;
    countdownPhase = 0; // Reset countdown
    isWaitingForBids = true;
  }

  void resetForNextPlayer() {
    currentPlayerIndex++;
    highestBid = 0;
    highestBidder = '';
    highestBidderTeam = '';
    countdownPhase = 0;
    isWaitingForBids = false;
  }

  GameTeam? getWinningTeam() {
    if (highestBidderTeam.isEmpty) return null;
    return teams.firstWhere((t) => t.teamName == highestBidderTeam);
  }
}
