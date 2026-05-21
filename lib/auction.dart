import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ipl_auction_game/parameters.dart';
import 'package:ipl_auction_game/summary.dart';
import 'package:ipl_auction_game/teamoverview.dart';
import 'package:ipl_auction_game/playerslist.dart';
import 'package:ipl_auction_game/models.dart';
import 'package:ipl_auction_game/notifications.dart';

class AuctionPage extends StatefulWidget {
  final AuctionState auctionState;
  final String currentPlayerName;
  const AuctionPage({
    super.key,
    required this.auctionState,
    required this.currentPlayerName,
  });

  @override
  State<AuctionPage> createState() => _AuctionPageState();
}

class _AuctionPageState extends State<AuctionPage> {
  late AuctionState auctionState;
  Timer? _countdownTimer;
  int _auctionPhase =
      0; // 0=bidding, 1=going once, 2=going twice, 3=sold, 4=retention
  String _phaseText = 'Place your bids';
  int _timeRemaining = 10; // seconds for initial bidding

  @override
  void initState() {
    super.initState();
    auctionState = widget.auctionState;
    _startBiddingPhase();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startBiddingPhase() {
    _countdownTimer?.cancel();
    setState(() {
      _auctionPhase = 0;
      _phaseText = 'Place your bids';
      _timeRemaining = 10;
    });

    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() => _timeRemaining--);

      if (_timeRemaining <= 0) {
        timer.cancel();
        if (auctionState.highestBid == 0) {
          // No bids, player unsold
          _handleUnsold();
        } else {
          // Start "going once" countdown
          _startGoingOnce();
        }
      }
    });
  }

  void _startGoingOnce() {
    _countdownTimer?.cancel();
    setState(() {
      _auctionPhase = 1;
      _phaseText = 'Going Once!';
      _timeRemaining = 3;
    });

    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() => _timeRemaining--);

      if (_timeRemaining <= 0) {
        timer.cancel();
        _startGoingTwice();
      }
    });
  }

  void _startGoingTwice() {
    _countdownTimer?.cancel();
    setState(() {
      _auctionPhase = 2;
      _phaseText = 'Going Twice!';
      _timeRemaining = 3;
    });

    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() => _timeRemaining--);

      if (_timeRemaining <= 0) {
        timer.cancel();
        _handleSold();
      }
    });
  }

  void _handleSold() {
    setState(() {
      _auctionPhase = 3;
      _phaseText = 'SOLD!';
    });

    final winningTeam = auctionState.getWinningTeam();
    if (winningTeam != null) {
      // Check foreign player limit
      if (auctionState.currentPlayer.isForeign &&
          !winningTeam.canAddForeignPlayer()) {
        showError(context, 'Cannot buy: Max 4 foreign players allowed');
        _moveToNextPlayer();
        return;
      }

      // Check WK-Batsman limit
      if (auctionState.currentPlayer.role.toLowerCase().contains('wk') &&
          !winningTeam.canAddWicketKeeper()) {
        showError(context, 'Cannot buy: Max 1 WK-Batsman per team');
        _moveToNextPlayer();
        return;
      }

      winningTeam.addPlayer(
        auctionState.currentPlayer.name,
        auctionState.highestBid,
        auctionState.currentPlayer.isForeign,
        auctionState.currentPlayer.role,
      );

      // Mark player as sold
      auctionState.currentPlayer.markAsSold(
        winningTeam.teamName,
        auctionState.highestBid,
      );

      showSuccess(
        context,
        '${auctionState.currentPlayer.name} sold to ${winningTeam.teamName} for ₹${auctionState.highestBid}L',
      );
    }

    Future.delayed(Duration(seconds: 2), () {
      if (mounted) _moveToNextPlayer();
    });
  }

  void _handleUnsold() {
    setState(() {
      _auctionPhase = 3;
      _phaseText = 'UNSOLD';
    });

    // Mark player as unsold
    auctionState.currentPlayer.markAsUnsold();

    showInfo(context, '${auctionState.currentPlayer.name} went unsold');

    Future.delayed(Duration(seconds: 2), () {
      if (mounted) _checkRetentionAfterUnsold();
    });
  }

  void _checkRetentionAfterUnsold() {
    final currentPlayer = auctionState.currentPlayer;

    // Check if player has previous team and that team hasn't used retention
    if (currentPlayer.previousTeam != null) {
      final previousTeam = auctionState.teams.firstWhere(
        (t) => t.teamName == currentPlayer.previousTeam,
        orElse: () => auctionState.teams.first,
      );

      if (!previousTeam.hasUsedRetention && previousTeam.canBid(50)) {
        _startRetentionPhase(previousTeam);
        return;
      }
    }

    _moveToNextPlayer();
  }

  void _startRetentionPhase(GameTeam previousTeam) {
    _countdownTimer?.cancel();
    setState(() {
      _auctionPhase = 4; // Retention phase
      _phaseText = 'Retention Option';
      _timeRemaining = 10; // 10 seconds for retention decision
      auctionState.retentionRequestTeam = previousTeam.teamName;
      auctionState.isWaitingForHostApproval = false;
    });

    // Show retention request to previous team's player
    if (previousTeam.playerName == widget.currentPlayerName) {
      _showRetentionRequest(previousTeam);
    } else {
      // Start countdown for other players
      _startRetentionTimer();
    }
  }

  void _startRetentionTimer() {
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() => _timeRemaining--);

      if (_timeRemaining <= 0 || auctionState.isWaitingForHostApproval) {
        timer.cancel();
        if (!auctionState.isWaitingForHostApproval) {
          // Time expired, no retention
          _moveToNextPlayer();
        }
      }
    });
  }

  Future<void> _showRetentionRequest(GameTeam previousTeam) async {
    final wantsRetention = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: iconPurple.withAlpha(230),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Text(
              '💫 Retention Opportunity',
              style: TextStyle(color: iconGold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Your team (${previousTeam.teamName}) can retain ${auctionState.currentPlayer.name} for ₹50L.',
                  style: TextStyle(color: iconGold.withAlpha(200)),
                ),
                SizedBox(height: 12),
                Text(
                  '⚠️ This is your only retention chance!',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text('Decline', style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(
                  'Request Retention',
                  style: TextStyle(color: iconGold),
                ),
              ),
            ],
          ),
    );

    if (wantsRetention == true && mounted) {
      setState(() {
        auctionState.isWaitingForHostApproval = true;
        _phaseText = 'Waiting for Host Approval';
      });
      showInfo(context, 'Retention requested! Waiting for host approval...');
      _waitForHostApproval(previousTeam);
    } else {
      _moveToNextPlayer();
    }
  }

  void _waitForHostApproval(GameTeam previousTeam) {
    // Find host and show approval dialog
    final hostTeam = auctionState.teams.firstWhere((t) => t.isHost);

    if (hostTeam.playerName == widget.currentPlayerName) {
      _showHostApprovalDialog(previousTeam);
    }
    // In real multiplayer, host would see this on their device
  }

  Future<void> _showHostApprovalDialog(GameTeam previousTeam) async {
    final approved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: iconPurple.withAlpha(230),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Row(
              children: [
                Icon(Icons.admin_panel_settings, color: iconGold),
                SizedBox(width: 8),
                Text('Host Approval', style: TextStyle(color: iconGold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${previousTeam.playerName} wants to retain ${auctionState.currentPlayer.name} for ₹50L.',
                  style: TextStyle(color: iconGold.withAlpha(200)),
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconGold.withAlpha(50),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Team: ${previousTeam.teamName}',
                        style: TextStyle(color: iconGold, fontSize: 12),
                      ),
                      Text(
                        'Remaining: ₹${previousTeam.remaining}L',
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text('Reject', style: TextStyle(color: Colors.red)),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text('Approve', style: TextStyle(color: Colors.green)),
              ),
            ],
          ),
    );

    if (approved == true && mounted) {
      // Execute retention
      previousTeam.addPlayer(
        auctionState.currentPlayer.name,
        50,
        auctionState.currentPlayer.isForeign,
        auctionState.currentPlayer.role,
      );
      previousTeam.hasUsedRetention = true;
      showSuccess(
        context,
        '✅ Retention approved! ${auctionState.currentPlayer.name} retained by ${previousTeam.teamName}',
      );
      await Future.delayed(Duration(seconds: 2));
      _moveToNextPlayer();
    } else {
      showError(context, '❌ Retention rejected by host');
      await Future.delayed(Duration(seconds: 2));
      _moveToNextPlayer();
    }
  }

  void _moveToNextPlayer() {
    // Debug: log progression state to diagnose premature completion
    print('DEBUG: moveToNextPlayer currentIndex=${auctionState.currentPlayerIndex} players=${auctionState.playersToAuction.length}');
    if (auctionState.hasMorePlayers) {
      // Check if we should show team overview (after every 15 players)
      final shouldShowOverview =
          (auctionState.currentPlayerIndex + 1) % 15 == 0;
      // Check if we should show players list (after every 10 players)
      final shouldShowPlayersList =
          (auctionState.currentPlayerIndex + 1) % 10 == 0;

      if (shouldShowPlayersList) {
        // Show players list after every 10 players
        final hostTeam = auctionState.teams.firstWhere((t) => t.isHost);
        final isHost = hostTeam.playerName == widget.currentPlayerName;

        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder:
                (_, __, ___) => PlayersListPage(
                  allPlayers: auctionState.playersToAuction,
                  teams: auctionState.teams,
                  currentPlayerName: widget.currentPlayerName,
                  isHost: isHost,
                  onContinue: () {
                    auctionState.resetForNextPlayer();
                    Navigator.pop(context);
                    setState(() {});
                    _startBiddingPhase();
                  },
                ),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
            transitionsBuilder: (_, __, ___, child) => child,
          ),
        );
      } else if (shouldShowOverview) {
        // Show team overview after every 15 players
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder:
                (_, __, ___) => TeamOverviewPage(
                  teams: auctionState.teams,
                  currentPlayerName: widget.currentPlayerName,
                  onContinue: () {
                    auctionState.resetForNextPlayer();
                    Navigator.pop(context);
                    setState(() {});
                    _startBiddingPhase();
                  },
                ),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
            transitionsBuilder: (_, __, ___, child) => child,
          ),
        );
      } else {
        // Continue to next player without overview
        auctionState.resetForNextPlayer();
        setState(() {});
        _startBiddingPhase();
      }
    } else {
      // Auction complete
      print('DEBUG: Auction complete reached. currentIndex=${auctionState.currentPlayerIndex} players=${auctionState.playersToAuction.length}');
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => SummaryPage(teams: auctionState.teams),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          transitionsBuilder: (_, __, ___, child) => child,
        ),
      );
    }
  }

  void _placeBid(GameTeam team) {
    if (_auctionPhase >= 3) return; // Cannot bid if sold/unsold

    final increment = auctionState.getNextBidIncrement(auctionState.highestBid);
    final nextBid = auctionState.highestBid + increment;

    if (!team.canBid(nextBid)) {
      showError(
        context,
        'Insufficient balance! Remaining: ₹${team.remaining}L',
      );
      return;
    }

    setState(() {
      auctionState.placeBid(team.playerName, team.teamName, nextBid);
    });

    // Reset to bidding phase if in countdown
    if (_auctionPhase > 0) {
      _startBiddingPhase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = auctionState.currentPlayer;
    final increment = auctionState.getNextBidIncrement(auctionState.highestBid);

    // Find current user's team
    final myTeam = auctionState.teams.firstWhere(
      (t) => t.playerName == widget.currentPlayerName,
      orElse: () => auctionState.teams.first,
    );
    final nextBid = auctionState.highestBid + increment;
    final canIBid = myTeam.canBid(nextBid) && _auctionPhase < 3;

    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                backgroundColor: iconPurple.withAlpha(230),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
        return shouldExit ?? false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              // Top Bar - Player Progress & Timer
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      iconPurple.withAlpha(250),
                      iconPurple.withAlpha(200),
                    ],
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
                                    pageBuilder:
                                        (_, __, ___) => TeamOverviewPage(
                                          teams: auctionState.teams,
                                          currentPlayerName:
                                              widget.currentPlayerName,
                                        ),
                                    transitionDuration: Duration.zero,
                                    reverseTransitionDuration: Duration.zero,
                                    transitionsBuilder:
                                        (_, __, ___, child) => child,
                                  ),
                                );
                              },
                              icon: Icon(
                                Icons.leaderboard,
                                color: iconGold,
                                size: 24,
                              ),
                              tooltip: 'View Teams',
                            ),
                            IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder:
                                        (_, __, ___) => PlayersListPage(
                                          allPlayers:
                                              auctionState.playersToAuction,
                                          teams: auctionState.teams,
                                          currentPlayerName:
                                              widget.currentPlayerName,
                                          isHost:
                                              auctionState.teams
                                                  .firstWhere((t) => t.isHost)
                                                  .playerName ==
                                              widget.currentPlayerName,
                                        ),
                                    transitionDuration: Duration.zero,
                                    reverseTransitionDuration: Duration.zero,
                                    transitionsBuilder:
                                        (_, __, ___, child) => child,
                                  ),
                                );
                              },
                              icon: Icon(
                                Icons.list_alt,
                                color: iconGold,
                                size: 24,
                              ),
                              tooltip: 'View All Players',
                            ),
                            Text(
                              'Player ${auctionState.currentPlayerIndex + 1}/${auctionState.playersToAuction.length}',
                              style: TextStyle(
                                color: iconGold,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color:
                                _auctionPhase == 4
                                    ? Colors.purple
                                    : _auctionPhase == 3
                                    ? (_phaseText == 'SOLD!'
                                        ? Colors.green
                                        : Colors.orange)
                                    : _auctionPhase >= 1
                                    ? Colors.red
                                    : iconGold.withAlpha(200),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child:
                              _auctionPhase < 3 || _auctionPhase == 4
                                  ? Text(
                                    '$_timeRemaining s',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  )
                                  : Icon(
                                    _phaseText == 'SOLD!'
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
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
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Player Card - Modern Design
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                iconGold.withAlpha(50),
                                iconPurple.withAlpha(80),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: iconGold.withAlpha(100),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: iconGold.withAlpha(100),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 60,
                                  backgroundColor: iconGold,
                                  child: Icon(
                                    Icons.person,
                                    size: 60,
                                    color: iconPurple,
                                  ),
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                player.name,
                                style: TextStyle(
                                  color: iconGold,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildInfoChip(
                                    player.role,
                                    Icons.sports_cricket,
                                  ),
                                  SizedBox(width: 12),
                                  _buildInfoChip(
                                    'Avg ${player.avgScore}',
                                    Icons.bar_chart,
                                  ),
                                  if (player.isForeign) ...[
                                    SizedBox(width: 12),
                                    _buildInfoChip(
                                      'Foreign',
                                      Icons.flag,
                                      Colors.blue.withAlpha(200),
                                    ),
                                  ],
                                ],
                              ),
                              if (player.previousTeam != null) ...[
                                SizedBox(height: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: iconGold.withAlpha(150),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Previous: ${player.previousTeam}',
                                    style: TextStyle(
                                      color: iconPurple,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(height: 20),

                        // Current Bid Display - Modern
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                iconGold.withAlpha(200),
                                iconGold.withAlpha(100),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: iconGold.withAlpha(50),
                                blurRadius: 15,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                'CURRENT BID',
                                style: TextStyle(
                                  color: iconPurple,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                auctionState.highestBid == 0
                                    ? 'NO BIDS'
                                    : '₹ ${auctionState.highestBid} L',
                                style: TextStyle(
                                  color: iconPurple,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (auctionState.highestBidder.isNotEmpty)
                                Text(
                                  auctionState.highestBidderTeam,
                                  style: TextStyle(
                                    color: iconPurple.withAlpha(180),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(height: 24),

                        // My Team Bid Button - Large Circular
                        if (canIBid) ...[
                          Text(
                            'TAP TO BID',
                            style: TextStyle(
                              color: iconGold,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          SizedBox(height: 16),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.95, end: 1.0),
                            duration: Duration(milliseconds: 800),
                            curve: Curves.easeInOut,
                            builder: (context, scale, child) {
                              return Transform.scale(
                                scale: scale,
                                child: GestureDetector(
                                  onTap: () {
                                    _placeBid(myTeam);
                                    showSuccess(
                                      context,
                                      '💰 Bid placed: ₹$nextBid L!',
                                    );
                                  },
                                  child: Container(
                                    width: 180,
                                    height: 180,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          iconGreen,
                                          iconGreen.withAlpha(200),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: iconGreen.withAlpha(100),
                                          blurRadius: 30,
                                          spreadRadius: 10,
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.gavel,
                                          size: 50,
                                          color: Colors.white,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          '₹$nextBid L',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'BID NOW',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 24),
                        ] else if (_auctionPhase >= 3) ...[
                          Container(
                            padding: EdgeInsets.all(20),
                            child: Text(
                              _phaseText,
                              style: TextStyle(
                                color:
                                    _phaseText == 'SOLD!'
                                        ? Colors.green
                                        : Colors.orange,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ] else ...[
                          Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey.withAlpha(80),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.block, size: 50, color: Colors.grey),
                                SizedBox(height: 8),
                                Text(
                                  'Insufficient\nBalance',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 24),
                        ],

                        // All Teams Status
                        Text(
                          'ALL TEAMS',
                          style: TextStyle(
                            color: iconGold,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        SizedBox(height: 12),
                        ...auctionState.teams.map((team) {
                          final isMyTeam =
                              team.playerName == widget.currentPlayerName;
                          final isWinning =
                              team.teamName == auctionState.highestBidderTeam;
                          return Container(
                            margin: EdgeInsets.only(bottom: 12),
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors:
                                    isMyTeam
                                        ? [
                                          iconGold.withAlpha(150),
                                          iconGold.withAlpha(80),
                                        ]
                                        : [
                                          iconPurple.withAlpha(150),
                                          iconPurple.withAlpha(80),
                                        ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color:
                                    isWinning
                                        ? iconGold
                                        : Colors.grey.withAlpha(100),
                                width: isWinning ? 3 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (isMyTeam)
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: iconPurple,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          'YOU',
                                          style: TextStyle(
                                            color: iconGold,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    if (isMyTeam) SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        team.teamName,
                                        style: TextStyle(
                                          color: iconGold,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                    if (isWinning)
                                      Icon(
                                        Icons.star,
                                        color: iconGold,
                                        size: 24,
                                      ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '${team.playerName}',
                                  style: TextStyle(
                                    color: iconGold.withAlpha(180),
                                    fontSize: 12,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildTeamStat(
                                      'Balance',
                                      '₹${team.remaining}L',
                                      Colors.green,
                                    ),
                                    _buildTeamStat(
                                      'Players',
                                      '${team.playersCount}',
                                      Colors.blue,
                                    ),
                                    _buildTeamStat(
                                      'Foreign',
                                      '${team.foreignPlayersCount}/4',
                                      Colors.orange,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
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

  Widget _buildInfoChip(String text, IconData icon, [Color? bgColor]) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor ?? iconPurple.withAlpha(150),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconGold),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: iconGold,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: iconGold.withAlpha(150),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
