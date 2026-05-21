import 'package:flutter/material.dart';
import 'package:ipl_auction_game/parameters.dart';
import 'package:ipl_auction_game/teamselection.dart';
import 'package:ipl_auction_game/models.dart';
import 'package:ipl_auction_game/notifications.dart';

class Lobby extends StatefulWidget {
  final String roomCode;
  final bool isHost;
  final String currentPlayerName;
  const Lobby({super.key, required this.roomCode, this.isHost = false, required this.currentPlayerName});

  @override
  State<Lobby> createState() => _LobbyState();
}

class _LobbyState extends State<Lobby> {
  // Mock player data; replace with Firebase StreamBuilder later
  final List<Map<String, dynamic>> players = [
    {'name': 'Player 1 (Host)', 'ready': true, 'isHost': true},
    {'name': 'Player 2', 'ready': true, 'isHost': false},
    {'name': 'Player 3', 'ready': true, 'isHost': false},
    // {'name': 'Player 2', 'ready': false, 'isHost': false},
    // {'name': 'Player 3', 'ready': false, 'isHost': false},
  ];

  bool isCurrentPlayerReady = false;

  bool get allPlayersReady => players.every((p) => p['ready'] == true);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final hei = size.height;

    return WillPopScope(
      onWillPop: () async {
        final shouldLeave = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: iconPurple.withAlpha(230),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Text('Leave Lobby?', style: TextStyle(color: iconGold)),
            content: Text(
              'Are you sure you want to leave this lobby?',
              style: TextStyle(color: iconGold.withAlpha(200)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text('Stay', style: TextStyle(color: iconGold)),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text('Leave', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        return shouldLeave ?? false;
      },
      child: Scaffold(
        backgroundColor: iconGreen.withAlpha(100),
        appBar: AppBar(
          backgroundColor: iconGreen.withAlpha(100),
          title: Text(
            'Lobby - ${widget.roomCode}',
            style: TextStyle(color: iconGold, fontWeight: FontWeight.bold),
          ),
        ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'Players Connected',
                  style: TextStyle(
                    color: iconGold,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: hei * 0.05),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: players.length,
                  itemBuilder: (ctx, idx) {
                    final p = players[idx];
                    return AnimatedScale(
                      scale: p['ready'] ? 1.0 : 0.95,
                      duration: Duration(milliseconds: 300),
                      child: Card(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      color: iconPurple.withAlpha(200),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: p['ready'] ? iconGold : Colors.grey,
                          width: 2,
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: iconGold,
                          child: Icon(Icons.person, color: iconPurple),
                        ),
                        title: Text(p['name'], style: TextStyle(color: iconGold)),
                        trailing: p['ready']
                            ? Icon(Icons.check_circle, color: iconGold)
                            : Icon(Icons.hourglass_empty, color: Colors.grey),
                      ),
                      ),
                    );
                  },
                ),
                SizedBox(height: hei * 0.05),
                Wrap(
                  spacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.95, end: 1.0),
                      duration: Duration(milliseconds: 600),
                      curve: Curves.easeInOut,
                      builder: (context, scale, child) {
                        return Transform.scale(
                          scale: scale,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() => isCurrentPlayerReady = !isCurrentPlayerReady);
                              if (isCurrentPlayerReady) {
                                showSuccess(context, '✅ You are ready!');
                              } else {
                                showInfo(context, 'Marked as not ready');
                              }
                              // In real implementation: update Firebase with ready status
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCurrentPlayerReady ? iconGold : Colors.grey,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        isCurrentPlayerReady ? 'Ready ✓' : 'Not Ready',
                        style: TextStyle(
                          color: iconPurple,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                          ),
                        );
                      },
                    ),
                    if (widget.isHost)
                      ElevatedButton(
                        onPressed: allPlayersReady
                            ? () {
                                if (mounted) {
                                  showSuccess(context, '🎮 Starting game...');
                                  
                                  Future.delayed(Duration(milliseconds: 800), () {
                                    if (!mounted) return;
                                    
                                    // Create GameTeam objects for each player
                                    final gameTeams = players
                                        .map((p) => GameTeam(
                                              playerName: p['name'],
                                              teamName: '', // Will be selected in TeamSelection
                                              isHost: p['isHost'] ?? false,
                                            ))
                                        .toList();

                                    Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (_, __, ___) => TeamSelection(teams: gameTeams, currentPlayerName: widget.currentPlayerName),
                                      transitionDuration: Duration.zero,
                                      reverseTransitionDuration: Duration.zero,
                                      transitionsBuilder: (_, __, ___, child) => child,
                                      ),
                                    );
                                  });
                                }
                              }
                            : () {
                                showError(context, 'Wait for all players to be ready');
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: allPlayersReady ? iconGreen : Colors.grey,
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_arrow, color: iconGold),
                            SizedBox(width: 4),
                            Text(
                              'Start Game',
                              style: TextStyle(color: iconGold, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: iconPurple.withAlpha(150),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Waiting for host to start...',
                          style: TextStyle(
                            color: iconGold.withAlpha(180),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}
