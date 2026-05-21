import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ipl_auction_game/models/room_player_model.dart';
import 'package:ipl_auction_game/providers/app_providers.dart';
import 'package:ipl_auction_game/providers/room_controller.dart';
import 'package:ipl_auction_game/screens/home_screen.dart';
import 'package:ipl_auction_game/widgets/glass_card.dart';
import 'package:ipl_auction_game/widgets/podium_card.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = ref.watch(roomControllerProvider).value;

    ref.listen(roomControllerProvider, (previous, next) {
      if (previous?.value != null && next.value == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) {
            return;
          }
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        });
      }
    });

    if (room == null) {
      return const Scaffold(body: Center(child: Text('No results found')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: FutureBuilder<List<RoomPlayerModel>>(
        future: ref.read(databaseServiceProvider).getRoomPlayers(room.roomId),
        builder: (context, snapshot) {
          final players = snapshot.data ?? const <RoomPlayerModel>[];
          final top = players.take(3).toList();

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Auction Summary', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text('Room code: ${room.roomCode}'),
                      Text('Players joined: ${players.length}/${room.maxPlayers}'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (top.isNotEmpty)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (top.length > 1)
                        PodiumCard(name: top[1].username, points: 0, rank: 2),
                      PodiumCard(name: top[0].username, points: 0, rank: 1),
                      if (top.length > 2)
                        PodiumCard(name: top[2].username, points: 0, rank: 3),
                    ],
                  ),
                const SizedBox(height: 12),
                Expanded(
                  child: GlassCard(
                    child: ListView.separated(
                      itemBuilder: (_, i) {
                        final player = players[i];
                        return Row(
                          children: [
                            SizedBox(width: 30, child: Text('#${i + 1}')),
                            Expanded(child: Text(player.username)),
                            Text(player.teamName == null || player.teamName!.isEmpty ? 'No team' : player.teamName!),
                          ],
                        );
                      },
                      separatorBuilder: (_, __) => const Divider(height: 18),
                      itemCount: players.length,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
