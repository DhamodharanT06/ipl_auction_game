import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ipl_auction_game/models/room_player_model.dart';
import 'package:ipl_auction_game/providers/app_providers.dart';
import 'package:ipl_auction_game/providers/room_controller.dart';
import 'package:ipl_auction_game/screens/home_screen.dart';
import 'package:ipl_auction_game/widgets/glass_card.dart';

class TeamOverviewScreen extends ConsumerStatefulWidget {
  const TeamOverviewScreen({super.key});

  @override
  ConsumerState<TeamOverviewScreen> createState() => _TeamOverviewScreenState();
}

class _TeamOverviewScreenState extends ConsumerState<TeamOverviewScreen> {
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
    final room = ref.watch(roomControllerProvider).value;

    ref.listen(roomControllerProvider, (previous, next) {
      if (previous?.value != null && next.value == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _goHome());
      }
    });

    if (room == null) {
      return const Scaffold(body: Center(child: Text('Room unavailable')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Overview'),
      ),
      body: FutureBuilder<List<RoomPlayerModel>>(
        future: ref.read(databaseServiceProvider).getRoomPlayers(room.roomId),
        builder: (context, snapshot) {
          final players = snapshot.data ?? const <RoomPlayerModel>[];
          if (players.isEmpty) {
            return const Center(child: CircularProgressIndicator());
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
                      Text('Room ${room.roomCode}', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text('${players.length}/${room.maxPlayers} players joined'),
                      const SizedBox(height: 6),
                      Text('This page shows who has joined and which IPL team they selected.'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemBuilder: (_, index) {
                      final player = players[index];
                      return ListTile(
                        tileColor: Theme.of(context).colorScheme.surface,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        leading: CircleAvatar(
                          child: Text(player.username.isNotEmpty ? player.username[0].toUpperCase() : '?'),
                        ),
                        title: Text(player.username),
                        subtitle: Text(player.teamName == null || player.teamName!.isEmpty
                            ? 'Team not selected'
                            : 'Team: ${player.teamName}'),
                        trailing: Icon(
                          player.isHost ? Icons.verified : Icons.person,
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemCount: players.length,
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
