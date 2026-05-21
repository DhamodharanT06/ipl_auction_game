import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:ipl_auction_game/models/room_model.dart';
import 'package:ipl_auction_game/models/room_player_model.dart';
import 'package:ipl_auction_game/providers/app_providers.dart';
import 'package:ipl_auction_game/providers/room_controller.dart';
import 'package:ipl_auction_game/providers/session_controller.dart';
import 'package:ipl_auction_game/screens/home_screen.dart';
import 'package:ipl_auction_game/screens/auction_screen.dart';
import 'package:ipl_auction_game/screens/leaderboard_screen.dart';
import 'package:ipl_auction_game/screens/team_selection_screen.dart';
import 'package:ipl_auction_game/widgets/glass_card.dart';
import 'package:ipl_auction_game/widgets/neon_button.dart';

class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({super.key});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  bool _redirectingHome = false;

  void _goHome() {
    if (_redirectingHome || !mounted) {
      return;
    }
    _redirectingHome = true;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final roomAsync = ref.watch(roomControllerProvider);
    final isHost = ref.watch(isHostProvider);

    ref.listen(roomControllerProvider, (previous, next) {
      if (previous?.value != null && next.value == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _goHome());
      } else if (previous?.value?.status != RoomStatus.inAuction && next.value?.status == RoomStatus.inAuction) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) {
            return;
          }
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AuctionScreen()),
          );
        });
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Lobby')),
      body: roomAsync.when(
        data: (room) {
          if (room == null) {
            return const Center(child: Text('No room selected'));
          }

          if (room.status == RoomStatus.completed) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
              );
            });
          }

          final currentUid = ref.watch(sessionControllerProvider.select((state) => state.uid));

          return StreamBuilder<List<RoomPlayerModel>>(
            stream: ref.read(realtimeServiceProvider).subscribeToRoomPlayers(
              room.roomId,
              () => ref.read(databaseServiceProvider).getRoomPlayers(room.roomId),
            ),
            builder: (context, snapshot) {
              final players = snapshot.data ?? const <RoomPlayerModel>[];
              RoomPlayerModel? currentPlayer;
              if (currentUid != null) {
                for (final player in players) {
                  if (player.userId == currentUid) {
                    currentPlayer = player;
                    break;
                  }
                }
              }

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.meeting_room, size: 18),
                              const SizedBox(width: 8),
                              const Text('Room Code'),
                              const Spacer(),
                              IconButton(
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: room.roomCode));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Room code copied')),
                                  );
                                },
                                icon: const Icon(Icons.copy),
                              ),
                            ],
                          ),
                          SelectableText(
                            room.roomCode,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 8),
                          Text('${players.length}/${room.maxPlayers} players joined'),
                          const SizedBox(height: 4),
                          Text(
                            currentPlayer?.teamName == null || currentPlayer?.teamName!.isEmpty == true
                                ? 'Choose your team before the host starts the auction.'
                                : 'Your team: ${currentPlayer!.teamName}',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: GlassCard(
                        child: ListView.separated(
                          itemBuilder: (_, index) {
                            final player = players[index];
                            return ListTile(
                              leading: CircleAvatar(
                                child: Text(
                                  player.username.isNotEmpty
                                      ? player.username[0].toUpperCase()
                                      : '?',
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(child: Text(player.username)),
                                  if (player.isHost)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 8),
                                      child: Chip(label: Text('HOST')),
                                    ),
                                ],
                              ),
                              subtitle: Text(
                                player.teamName == null || player.teamName!.isEmpty
                                    ? (player.isReady ? 'Ready - no team yet' : 'Waiting')
                                    : '${player.isReady ? 'Ready' : 'Waiting'} • Team ${player.teamName}',
                              ),
                              trailing: Icon(
                                player.isReady ? Icons.check_circle : Icons.hourglass_empty,
                              ),
                            );
                          },
                          separatorBuilder: (_, __) => const Divider(height: 16),
                          itemCount: players.length,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    NeonButton(
                      label: isHost ? 'Start Team Selection' : 'Choose Team',
                      icon: Icons.sports_cricket,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const TeamSelectionScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    const SizedBox(height: 10),
                    if (isHost)
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          NeonButton(
                            label: 'Approve & Start Auction',
                            icon: Icons.play_arrow,
                            onTap: () async {
                              // Ask host if they want to play or just conduct
                              showDialog(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: const Text('Choose Your Role'),
                                  content: const Text('Do you want to play in this auction or just conduct it?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(dialogContext),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        Navigator.pop(dialogContext);
                                        // Host wants to conduct only
                                        await ref.read(databaseServiceProvider).updateRoomFields(
                                          room.roomId,
                                          {'hostMode': 'conduct'},
                                        );
                                        // Proceed to auction
                                        try {
                                          await ref.read(roomControllerProvider.notifier).startAuction(null);
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Error: $e')),
                                            );
                                          }
                                        }
                                      },
                                      child: const Text('Just Conduct'),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        Navigator.pop(dialogContext);
                                        // Host wants to play
                                        await ref.read(databaseServiceProvider).updateRoomFields(
                                          room.roomId,
                                          {'hostMode': 'play'},
                                        );
                                        // Proceed to auction
                                        try {
                                          await ref.read(roomControllerProvider.notifier).startAuction(null);
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Error: $e')),
                                            );
                                          }
                                        }
                                      },
                                      child: const Text('Play & Bid'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          NeonButton(
                            label: 'Leave Room',
                            icon: Icons.exit_to_app,
                            onTap: () async {
                              await ref.read(roomControllerProvider.notifier).leaveRoom();
                            },
                          ),
                          NeonButton(
                            label: 'Delete Room',
                            icon: Icons.delete_forever,
                            onTap: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: const Text('Delete room?'),
                                  content: const Text('This will remove the room for everyone.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(dialogContext).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(dialogContext).pop(true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await ref.read(roomControllerProvider.notifier).deleteRoom();
                              }
                            },
                          ),
                        ],
                      )
                    else
                      NeonButton(
                        label: 'Exit Room',
                        icon: Icons.logout,
                        onTap: () async {
                          await ref.read(roomControllerProvider.notifier).leaveRoom();
                        },
                      ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }
}
