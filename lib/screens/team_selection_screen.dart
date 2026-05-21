import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ipl_auction_game/models/room_model.dart';
import 'package:ipl_auction_game/models/room_player_model.dart';
import 'package:ipl_auction_game/providers/app_providers.dart';
import 'package:ipl_auction_game/providers/room_controller.dart';
import 'package:ipl_auction_game/providers/session_controller.dart';
import 'package:ipl_auction_game/screens/auction_screen.dart';
import 'package:ipl_auction_game/screens/home_screen.dart';
import 'package:ipl_auction_game/widgets/glass_card.dart';

class TeamSelectionScreen extends ConsumerStatefulWidget {
  const TeamSelectionScreen({super.key});

  @override
  ConsumerState<TeamSelectionScreen> createState() =>
      _TeamSelectionScreenState();
}

class _FranchiseTheme {
  const _FranchiseTheme({
    required this.code,
    required this.name,
    required this.logo,
    required this.primary,
    required this.secondary,
    required this.ownerLine,
  });

  final String code;
  final String name;
  final String logo;
  final Color primary;
  final Color secondary;
  final String ownerLine;
}

class _TeamSelectionScreenState extends ConsumerState<TeamSelectionScreen> {
  static const List<_FranchiseTheme> _franchises = [
    _FranchiseTheme(
      code: 'MI',
      name: 'Mumbai Indians',
      logo: '🔵',
      primary: Color(0xFF0A4EA1),
      secondary: Color(0xFFB9D4FF),
      ownerLine: 'Five-time champions, built for power play dominance.',
    ),
    _FranchiseTheme(
      code: 'CSK',
      name: 'Chennai Super Kings',
      logo: '🦁',
      primary: Color(0xFFF4B400),
      secondary: Color(0xFFFFE08A),
      ownerLine: 'Yellow fortress with elite finishing instincts.',
    ),
    _FranchiseTheme(
      code: 'RCB',
      name: 'Royal Challengers Bangalore',
      logo: '🔴',
      primary: Color(0xFFDA1E28),
      secondary: Color(0xFFFFA2A8),
      ownerLine: 'High intensity, high passion, premium batting identity.',
    ),
    _FranchiseTheme(
      code: 'KKR',
      name: 'Kolkata Knight Riders',
      logo: '💜',
      primary: Color(0xFF5B2DAA),
      secondary: Color(0xFFD8B7FF),
      ownerLine: 'Purple courage with a tactical edge.',
    ),
    _FranchiseTheme(
      code: 'SRH',
      name: 'Sunrisers Hyderabad',
      logo: '🌅',
      primary: Color(0xFFFF7A1A),
      secondary: Color(0xFFFFD4A8),
      ownerLine: 'Explosive sunrise franchise with fearless cricket.',
    ),
    _FranchiseTheme(
      code: 'DC',
      name: 'Delhi Capitals',
      logo: '🔷',
      primary: Color(0xFF1E88E5),
      secondary: Color(0xFF8FD3FF),
      ownerLine: 'Blue fire, fast tempo, and bold squad building.',
    ),
    _FranchiseTheme(
      code: 'RR',
      name: 'Rajasthan Royals',
      logo: '👑',
      primary: Color(0xFFE91E8F),
      secondary: Color(0xFFFFB3DD),
      ownerLine: 'Original champions with a royal recruitment style.',
    ),
    _FranchiseTheme(
      code: 'PBKS',
      name: 'Punjab Kings',
      logo: '🦁',
      primary: Color(0xFFE53935),
      secondary: Color(0xFFFFB9B7),
      ownerLine: 'Bold red identity with aggressive auction strategy.',
    ),
    _FranchiseTheme(
      code: 'GT',
      name: 'Gujarat Titans',
      logo: '🛡️',
      primary: Color(0xFF222222),
      secondary: Color(0xFFC7A76C),
      ownerLine: 'Modern powerhouse with disciplined squad structure.',
    ),
    _FranchiseTheme(
      code: 'LSG',
      name: 'Lucknow Super Giants',
      logo: '🐯',
      primary: Color(0xFF0057E2),
      secondary: Color(0xFFA91C5A),
      ownerLine: 'Sharp, fresh, and built for a premium debut impact.',
    ),
  ];

  Stream<List<RoomPlayerModel>>? _playersStream;
  bool _redirectingHome = false;
  bool _selecting = false;

  @override
  void initState() {
    super.initState();
    // Initialize stream in initState so it persists
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final room = ref.read(roomControllerProvider).value;
      if (room != null && _playersStream == null) {
        _loadPlayers(room.roomId);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

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

  void _loadPlayers(String roomId) {
    final realtime = ref.read(realtimeServiceProvider);
    final database = ref.read(databaseServiceProvider);
    _playersStream = realtime.subscribeToRoomPlayers(
      roomId,
      () => database.getRoomPlayers(roomId),
    );
  }

  Future<void> _selectTeam(
    String teamCode,
    RoomPlayerModel player,
    RoomModel room,
  ) async {
    setState(() => _selecting = true);
    try {
      await ref
          .read(databaseServiceProvider)
          .updateRoomPlayer(
            roomId: room.roomId,
            userId: player.userId,
            teamName: teamCode,
          );
      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ You selected $teamCode!'),
            duration: const Duration(milliseconds: 1200),
          ),
        );
        // Stream will automatically update through realtime subscription
        // No need to manually reload players
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _selecting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final room = ref.watch(roomControllerProvider).value;
    final uid = ref.watch(
      sessionControllerProvider.select((state) => state.uid),
    );

    ref.listen(roomControllerProvider, (previous, next) {
      if (previous?.value != null && next.value == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) {
            return;
          }
          _goHome();
        });
      } else if (previous?.value?.status != RoomStatus.inAuction &&
          next.value?.status == RoomStatus.inAuction) {
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

    if (room == null) {
      return const Scaffold(body: Center(child: Text('Room unavailable')));
    }

    if (_playersStream == null) {
      _loadPlayers(room.roomId);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Team'),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: StreamBuilder<List<RoomPlayerModel>>(
        stream: _playersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load teams: ${snapshot.error}'),
            );
          }

          final players = snapshot.data ?? const <RoomPlayerModel>[];
          if (players.isEmpty) {
            return const Center(child: Text('No players joined yet'));
          }

          final approvedPlayers =
              players.where((player) => player.isReady).toList();
          final takenTeams = <String>{};
          for (final p in approvedPlayers) {
            if (p.teamName != null && p.teamName!.isNotEmpty) {
              takenTeams.add(p.teamName!);
            }
          }

          final currentPlayer = players.firstWhere(
            (player) => player.userId == uid,
            orElse: () => players.first,
          );
          final currentTeamCode = currentPlayer.teamName;
          final isHost = ref.watch(isHostProvider);
          // Check if ALL players in the room have selected teams
          final allPlayersHaveTeams = players.isNotEmpty &&
              players.every(
                (player) =>
                    player.teamName != null && player.teamName!.isNotEmpty,
              );

          return SafeArea(
            child: Padding(
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
                            const Icon(Icons.shield),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Select Your IPL Team',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Room ${room.roomCode}'),
                        const SizedBox(height: 4),
                        Text(
                          'Pick one franchise from the 2-column grid. Grey boxes are already taken by another player.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (currentTeamCode != null &&
                            currentTeamCode.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            'Your current team: $currentTeamCode',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1,
                          ),
                      itemCount: _franchises.length,
                      itemBuilder: (context, index) {
                        final franchise = _franchises[index];
                        final isTaken = takenTeams.contains(franchise.code);
                        final isSelected = currentTeamCode == franchise.code;
                        final gradient =
                            isTaken && !isSelected
                                ? const LinearGradient(
                                  colors: [
                                    Color(0xFF4B5563),
                                    Color(0xFF374151),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                                : LinearGradient(
                                  colors: [
                                    franchise.primary.withOpacity(
                                      isSelected ? 1 : 0.88,
                                    ),
                                    franchise.secondary.withOpacity(
                                      isSelected ? 0.9 : 0.72,
                                    ),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                );

                        return InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap:
                              (isTaken && !isSelected) || _selecting
                                  ? null
                                  : () => _selectTeam(
                                    franchise.code,
                                    currentPlayer,
                                    room,
                                  ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: gradient,
                              border: Border.all(
                                color:
                                    isSelected ? Colors.white : Colors.white24,
                                width: isSelected ? 3 : 1,
                              ),
                              boxShadow:
                                  isSelected
                                      ? [
                                        BoxShadow(
                                          color: franchise.primary.withOpacity(
                                            0.45,
                                          ),
                                          blurRadius: 18,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                      : [],
                            ),
                            child: Stack(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.16,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            franchise.logo,
                                            style: const TextStyle(
                                              fontSize: 24,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        if (isSelected)
                                          const Icon(
                                            Icons.check_circle,
                                            color: Colors.white,
                                          ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          franchise.code,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Text(
                                            franchise.name,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(
                                              0.18,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                          ),
                                          child: Text(
                                            isTaken && !isSelected
                                                ? 'Taken'
                                                : isSelected
                                                ? 'Selected'
                                                : 'Available',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                if (isTaken && !isSelected)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.10),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (isHost)
                    FilledButton.icon(
                      onPressed:
                          allPlayersHaveTeams
                              ? () async {
                                final error = await ref
                                    .read(roomControllerProvider.notifier)
                                    .startAuction(null);
                                if (!context.mounted) {
                                  return;
                                }
                                if (error != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(error)),
                                  );
                                }
                              }
                              : null,
                      icon: const Icon(Icons.play_arrow),
                      label: Text(
                        allPlayersHaveTeams
                            ? 'Approve & Start Game'
                            : 'Waiting for all players to choose teams',
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.hourglass_top),
                          SizedBox(width: 8),
                          Text('Waiting for host approval'),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
