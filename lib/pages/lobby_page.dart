import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../parameters.dart';
import '../providers/game_provider.dart';
import '../notifications.dart';
import 'auction_page.dart';

class LobbyPage extends StatefulWidget {
  const LobbyPage({super.key});

  @override
  State<LobbyPage> createState() => _LobbyPageState();
}

class _LobbyPageState extends State<LobbyPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gameProvider = Provider.of<GameProvider>(context, listen: false);
      if (gameProvider.currentRoom != null) {
        gameProvider.loadRoomPlayers(gameProvider.currentRoom!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);
    final room = gameProvider.currentRoom;
    final players = gameProvider.roomPlayers;
    final isHost = gameProvider.isHost;
    final allReady = gameProvider.allPlayersReady;
    final size = MediaQuery.of(context).size;
    final hei = size.height;

    if (room == null) {
      return Scaffold(
        backgroundColor: iconGreen.withAlpha(100),
        appBar: AppBar(
          backgroundColor: iconGreen.withAlpha(100),
          title: Text('Lobby', style: TextStyle(color: iconGold)),
        ),
        body: Center(
          child: Text('No room found', style: TextStyle(color: iconGold)),
        ),
      );
    }

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
        if (shouldLeave ?? false) {
          await gameProvider.leaveRoom();
        }
        return shouldLeave ?? false;
      },
      child: Scaffold(
        backgroundColor: iconGreen.withAlpha(100),
        appBar: AppBar(
          backgroundColor: iconGreen.withAlpha(100),
          title: Text(
            'Lobby - ${room.roomCode}',
            style: TextStyle(color: iconGold, fontWeight: FontWeight.bold),
          ),
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Room Code Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: iconPurple.withAlpha(200),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: iconGold, width: 2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          room.roomCode,
                          style: TextStyle(
                            color: iconGold,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                          ),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: Icon(Icons.copy, color: iconGold),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: room.roomCode));
                            showSuccess(context, 'Code copied!');
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: hei * 0.03),
                  
                  Text(
                    'Players Connected (${players.length}/${room.maxPlayers})',
                    style: TextStyle(
                      color: iconGold,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  SizedBox(height: hei * 0.03),
                  
                  // Players List
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: players.length,
                    itemBuilder: (ctx, idx) {
                      final p = players[idx];
                      return AnimatedScale(
                        scale: p.isReady || p.isHost ? 1.0 : 0.95,
                        duration: const Duration(milliseconds: 300),
                        child: Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          color: iconPurple.withAlpha(200),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: p.isReady || p.isHost ? iconGold : Colors.grey,
                              width: 2,
                            ),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: iconGold,
                              child: Icon(Icons.person, color: iconPurple),
                            ),
                            title: Row(
                              children: [
                                Text(p.username, style: TextStyle(color: iconGold)),
                                if (p.isHost) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: iconGold,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'HOST',
                                      style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            trailing: p.isReady || p.isHost
                                ? Icon(Icons.check_circle, color: iconGold)
                                : Icon(Icons.hourglass_empty, color: Colors.grey),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  SizedBox(height: hei * 0.05),
                  
                  // Ready / Start Buttons
                  Wrap(
                    spacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      if (!isHost)
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.95, end: 1.0),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeInOut,
                          builder: (context, scale, child) {
                            return Transform.scale(
                              scale: scale,
                              child: ElevatedButton(
                                onPressed: () {
                                  gameProvider.toggleReady();
                                  if (gameProvider.currentRoomPlayer?.isReady ?? false) {
                                    showSuccess(context, '✅ You are ready!');
                                  } else {
                                    showInfo(context, 'Marked as not ready');
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: gameProvider.currentRoomPlayer?.isReady ?? false 
                                      ? iconGold 
                                      : Colors.grey,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: Text(
                                  gameProvider.currentRoomPlayer?.isReady ?? false ? 'Ready ✓' : 'Not Ready',
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
                      if (isHost)
                        ElevatedButton(
                          onPressed: allReady && players.length >= 2
                              ? () => _startAuction(gameProvider)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: allReady && players.length >= 2 ? iconGold : Colors.grey,
                            disabledBackgroundColor: Colors.grey,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(
                            allReady && players.length >= 2 ? 'Start Auction' : 'Waiting for players...',
                            style: TextStyle(
                              color: iconPurple,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
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

  Future<void> _startAuction(GameProvider gameProvider) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Center(
        child: CircularProgressIndicator(color: iconGold),
      ),
    );

    final success = await gameProvider.startAuction();

    if (!mounted) return;
    Navigator.of(context).pop();

    if (success) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const AuctionPage(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          transitionsBuilder: (_, __, ___, child) => child,
        ),
      );
    } else {
      showError(context, gameProvider.error ?? 'Failed to start auction');
    }
  }
}
