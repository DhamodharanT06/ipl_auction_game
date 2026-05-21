import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../parameters.dart';
import '../providers/game_provider.dart';
import '../providers/auth_provider.dart';
import '../notifications.dart';
import 'team_overview_page.dart';
import 'summary_page.dart';
import 'home_page.dart';

class AuctionPage extends StatefulWidget {
  const AuctionPage({super.key});

  @override
  State<AuctionPage> createState() => _AuctionPageState();
}

class _AuctionPageState extends State<AuctionPage> {
  String _phaseText = 'Place your bids';
  final Set<String> _skipVotes = {}; // Players who voted to skip

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final auction = gameProvider.currentAuction;
    final currentRoomPlayer = gameProvider.currentRoomPlayer;
    final isHost = gameProvider.isHost;

    if (auction == null) {
      return Scaffold(
        backgroundColor: iconGreen.withAlpha(100),
        appBar: AppBar(
          backgroundColor: iconGreen.withAlpha(100),
          title: Text('Auction', style: TextStyle(color: iconGold)),
        ),
        body: Center(
          child: Text('Loading auction...', style: TextStyle(color: iconGold)),
        ),
      );
    }

    // Check if auction is completed
    if (auction.status == 'completed') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => SummaryPage(teams: gameProvider.roomPlayers),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
            transitionsBuilder: (_, __, ___, child) => child,
          ),
        );
      });
    }

    final player = auction.players[auction.currentPlayerIndex];
    final playerName = player['name'] ?? 'Unknown';
    final playerRole = player['role'] ?? 'Unknown';
    final isForeign = player['isForeign'] ?? false;
    final avgScore = player['avgScore'] ?? 0;

    final nextBidIncrement = auction.getNextBidIncrement(auction.currentBid);
    final nextBid = auction.currentBid == 0 ? 20 : auction.currentBid + nextBidIncrement;
    final canBid = currentRoomPlayer != null && 
        currentRoomPlayer.budget >= nextBid && 
        auction.currentBidder != currentRoomPlayer.username;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: iconPurple.withAlpha(230),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Text('Exit Auction?', style: TextStyle(color: iconGold)),
            content: Text(
              'Auction is in progress. Are you sure you want to exit?',
              style: TextStyle(color: iconGold.withAlpha(200)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text('Stay', style: TextStyle(color: iconGold)),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text('Exit', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        if (shouldExit == true && mounted) {
          await gameProvider.leaveRoom();
          Navigator.of(context).pushAndRemoveUntil(
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const HomePage(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
              transitionsBuilder: (_, __, ___, child) => child,
            ),
            (route) => false,
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [iconPurple.withAlpha(250), iconPurple.withAlpha(200)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (_, __, ___) => TeamOverviewPage(
                                      teams: gameProvider.roomPlayers,
                                      currentPlayerName: authProvider.userProfile?.username,
                                    ),
                                    transitionDuration: Duration.zero,
                                    reverseTransitionDuration: Duration.zero,
                                    transitionsBuilder: (_, __, ___, child) => child,
                                  ),
                                );
                              },
                              icon: Icon(Icons.leaderboard, color: iconGold, size: 24),
                              tooltip: 'View Teams',
                            ),
                            Text(
                              'Player ${auction.currentPlayerIndex + 1}/${auction.players.length}',
                              style: TextStyle(
                                color: iconGold,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        // Budget display
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: iconGold.withAlpha(200),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '₹${currentRoomPlayer?.budget ?? 0}L',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _phaseText,
                      style: TextStyle(
                        color: iconGold,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Player Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [iconGold.withAlpha(50), iconPurple.withAlpha(80)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: iconGold, width: 2),
                          ),
                          child: Column(
                            children: [
                              // Foreign badge
                              if (isForeign)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withAlpha(150),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    '🌍 OVERSEAS',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 12),
                              // Player avatar
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: iconGold.withAlpha(100),
                                child: Text(
                                  playerName.isNotEmpty ? playerName[0].toUpperCase() : '?',
                                  style: TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: iconPurple,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                playerName,
                                style: TextStyle(
                                  color: iconGold,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(
                                  color: iconPurple.withAlpha(150),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  playerRole,
                                  style: TextStyle(
                                    color: iconGold,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Stats row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildStatBox('Rating', '$avgScore', Colors.greenAccent),
                                  _buildStatBox('Base', '₹20L', iconGold),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Current Bid Section
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: iconPurple.withAlpha(150),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: iconGold.withAlpha(100)),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'CURRENT BID',
                                style: TextStyle(
                                  color: iconGold.withAlpha(180),
                                  fontSize: 12,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                auction.currentBid > 0 ? '₹${auction.currentBid}L' : 'No bids yet',
                                style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (auction.currentBidder.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'by ${auction.currentBidder}',
                                  style: TextStyle(
                                    color: iconGold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Bid Button
                        if (canBid)
                          InkWell(
                            onTap: () => _placeBid(gameProvider, nextBid),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.green.shade700, Colors.green.shade500],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: iconGold, width: 2),
                              ),
                              child: Text(
                                'BID ₹${nextBid}L',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                        if (!canBid && currentRoomPlayer != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey.withAlpha(100),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              auction.currentBidder == currentRoomPlayer.username
                                  ? 'You are the highest bidder'
                                  : 'Insufficient budget',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: iconGold.withAlpha(150),
                                fontSize: 16,
                              ),
                            ),
                          ),

                        const SizedBox(height: 24),

                        // Skip Vote Button (for all players)
                        if (!_skipVotes.contains(authProvider.userProfile?.username ?? ''))
                          InkWell(
                            onTap: () => _voteToSkip(authProvider.userProfile?.username ?? ''),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withAlpha(100),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.orange),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.skip_next, color: Colors.orange),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Vote to Skip (${_skipVotes.length}/${gameProvider.roomPlayers.length})',
                                    style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        if (_skipVotes.contains(authProvider.userProfile?.username ?? ''))
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.withAlpha(50),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '✓ You voted to skip (${_skipVotes.length}/${gameProvider.roomPlayers.length})',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade400),
                            ),
                          ),

                        const SizedBox(height: 24),

                        // Host Controls
                        if (isHost) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: iconGold.withAlpha(30),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: iconGold),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.admin_panel_settings, color: iconGold),
                                    const SizedBox(width: 8),
                                    Text(
                                      'HOST CONTROLS',
                                      style: TextStyle(
                                        color: iconGold,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    // Sell Button
                                    Expanded(
                                      child: InkWell(
                                        onTap: auction.currentBid > 0 
                                            ? () => _sellPlayer(gameProvider) 
                                            : null,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          decoration: BoxDecoration(
                                            color: auction.currentBid > 0 
                                                ? Colors.green 
                                                : Colors.grey.withAlpha(100),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Text(
                                            'SELL',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Skip Button
                                    Expanded(
                                      child: InkWell(
                                        onTap: () => _skipPlayer(gameProvider),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          decoration: BoxDecoration(
                                            color: Colors.orange,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Text(
                                            'SKIP',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),

                        // All Teams Quick View
                        _buildTeamsQuickView(gameProvider),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(100),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(color: iconGold.withAlpha(150), fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamsQuickView(GameProvider gameProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: iconPurple.withAlpha(100),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TEAMS',
            style: TextStyle(
              color: iconGold,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ...gameProvider.roomPlayers.map((player) {
            final isCurrentBidder = gameProvider.currentAuction?.currentBidder == player.username;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isCurrentBidder ? iconGold.withAlpha(50) : Colors.black.withAlpha(50),
                borderRadius: BorderRadius.circular(8),
                border: isCurrentBidder ? Border.all(color: iconGold) : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (player.isHost) 
                        Icon(Icons.star, color: iconGold, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        player.username,
                        style: TextStyle(
                          color: isCurrentBidder ? iconGold : Colors.white,
                          fontWeight: isCurrentBidder ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '₹${player.budget}L',
                    style: TextStyle(
                      color: player.budget > 200 ? Colors.greenAccent : Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _placeBid(GameProvider gameProvider, int bidAmount) async {
    final success = await gameProvider.placeBid(bidAmount);
    if (success && mounted) {
      setState(() {
        _phaseText = 'New bid placed!';
        _skipVotes.clear(); // Clear skip votes on new bid
      });
    } else if (gameProvider.error != null && mounted) {
      showError(context, gameProvider.error!);
      gameProvider.clearError();
    }
  }

  void _voteToSkip(String username) {
    setState(() {
      _skipVotes.add(username);
    });
    showInfo(context, 'You voted to skip this player');
  }

  void _sellPlayer(GameProvider gameProvider) async {
    final auction = gameProvider.currentAuction;
    if (auction == null || auction.currentBid == 0) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: iconPurple.withAlpha(230),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Confirm Sale', style: TextStyle(color: iconGold)),
        content: Text(
          'Sell ${auction.currentPlayer.name} to ${auction.currentBidder} for ₹${auction.currentBid}L?',
          style: TextStyle(color: iconGold.withAlpha(200)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('SELL', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      showSuccess(
        context,
        '${auction.currentPlayer.name} sold to ${auction.currentBidder} for ₹${auction.currentBid}L!',
      );
      await gameProvider.sellPlayer();
      _resetForNextPlayer();
    }
  }

  void _skipPlayer(GameProvider gameProvider) async {
    final auction = gameProvider.currentAuction;
    if (auction == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: iconPurple.withAlpha(230),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Skip Player', style: TextStyle(color: iconGold)),
        content: Text(
          'Skip ${auction.currentPlayer.name}? They will go unsold.',
          style: TextStyle(color: iconGold.withAlpha(200)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('SKIP', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      showInfo(context, '${auction.currentPlayer.name} went unsold');
      await gameProvider.sellPlayer(); // This moves to next player
      _resetForNextPlayer();
    }
  }

  void _resetForNextPlayer() {
    setState(() {
      _phaseText = 'Place your bids';
      _skipVotes.clear();
    });
  }
}
