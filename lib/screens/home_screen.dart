import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:ipl_auction_game/config/appwrite_config.dart';
import 'package:ipl_auction_game/providers/room_controller.dart';
import 'package:ipl_auction_game/providers/session_controller.dart';
import 'package:ipl_auction_game/screens/lobby_screen.dart';
import 'package:ipl_auction_game/screens/profile_screen.dart';
import 'package:ipl_auction_game/screens/sheet_players_screen.dart';
import 'package:ipl_auction_game/widgets/glass_card.dart';
import 'package:ipl_auction_game/widgets/neon_button.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _roomController = TextEditingController();

  @override
  void dispose() {
    _roomController.dispose();
    super.dispose();
  }

  Future<void> _sendPing() async {
    try {
      final response = await http.get(
        Uri.parse('${AppwriteConfig.endpoint}/health/ping'),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Appwrite connection successful!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Ping failed with status ${response.statusCode}');
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✗ Connection failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _goLobby() async {
    if (!mounted) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LobbyScreen()),
    );
  }

  Future<int?> _askPlayerCount() async {
    final controller = TextEditingController(text: '4');
    try {
      return await showDialog<int>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Number of players'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Max players',
              hintText: 'Enter a number',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final count = int.tryParse(controller.text.trim());
                if (count == null || count < 2) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Enter at least 2 players')),
                  );
                  return;
                }
                Navigator.of(dialogContext).pop(count);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _createLobby() async {
    final maxPlayers = await _askPlayerCount();
    if (maxPlayers == null || !mounted) {
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final error = await ref.read(roomControllerProvider.notifier).createLobby(
          maxPlayers: maxPlayers,
        );

    if (!context.mounted) {
      return;
    }

    Navigator.of(context).pop();

    if (error == null) {
      await _goLobby();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionControllerProvider.select((s) => s.user));

    return Scaffold(
      appBar: AppBar(
        title: const Text('IPL Auction Arena'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_queue),
            tooltip: 'Send Ping',
            onPressed: _sendPing,
          ),
          IconButton(
            icon: const Icon(Icons.person_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF111827), Color(0xFF090B10)],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GlassCard(
              child: Row(
                children: [
                  const Icon(Icons.waving_hand, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Welcome, ${user?.username ?? 'Guest'}'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  NeonButton(
                    label: 'Create Lobby (Host)',
                    icon: Icons.add_circle_outline,
                    onTap: _createLobby,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _roomController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      hintText: 'Enter Room ID',
                    ),
                  ),
                  const SizedBox(height: 12),
                  NeonButton(
                    label: 'Join Lobby',
                    icon: Icons.login,
                    onTap: () async {
                      if (_roomController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Room ID is required')),
                        );
                        return;
                      }
                      final error = await ref
                          .read(roomControllerProvider.notifier)
                          .joinLobby(
                            _roomController.text.trim().toUpperCase(),
                          );
                      if (!context.mounted) {
                        return;
                      }
                      if (error == null) {
                        await _goLobby();
                      } else {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text(error)));
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  NeonButton(
                    label: 'Preview Sheet Players',
                    icon: Icons.table_chart,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SheetPlayersScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
