import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ipl_auction_game/core/constants/app_constants.dart';
import 'package:ipl_auction_game/models/player_model.dart';
import 'package:ipl_auction_game/models/room_model.dart';
import 'package:ipl_auction_game/models/room_player_model.dart';
import 'package:ipl_auction_game/providers/app_providers.dart';
import 'package:ipl_auction_game/providers/players_provider.dart';
import 'package:ipl_auction_game/providers/room_controller.dart';
import 'package:ipl_auction_game/providers/session_controller.dart';
import 'package:ipl_auction_game/screens/home_screen.dart';
import 'package:ipl_auction_game/screens/leaderboard_screen.dart';
import 'package:ipl_auction_game/screens/all_players_table_screen.dart';
import 'package:ipl_auction_game/screens/my_buys_screen.dart';
import 'package:ipl_auction_game/widgets/neon_button.dart';
import 'package:ipl_auction_game/widgets/player_image.dart';
import 'package:ipl_auction_game/widgets/shimmer_player_list.dart';

class AuctionScreen extends ConsumerStatefulWidget {
  const AuctionScreen({super.key});

  @override
  ConsumerState<AuctionScreen> createState() => _AuctionScreenState();
}

class _AuctionScreenState extends ConsumerState<AuctionScreen> {
  final _bidController = TextEditingController();
  int _currentIndex = 0;

  Timer? _countdownTimer;
  int _timeRemaining = 10;
  int _auctionPhase = 0;
  String _phaseText = 'Place your bids';

  final List<Map<String, dynamic>> _lastFiveBids = [];
  bool _placingBid = false;
  final Map<String, int> _playerBidTotal = {};
  final List<Map<String, dynamic>> _auctionResults = [];
  bool _redirectingHome = false;
  String? _lastBidsCacheKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(isHostProvider)) {
        _startTimerPhase();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _bidController.dispose();
    _placingBid = false;
    super.dispose();
  }

  void _goHome() {
    if (_redirectingHome || !mounted) return;
    _redirectingHome = true;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  void _startTimerPhase() {
    _countdownTimer?.cancel();
    setState(() {
      _timeRemaining = AppConstants.initialAuctionTimer;
      _auctionPhase = 0;
      _phaseText = 'Place your bids';
    });
    _tickTimer();
  }

  void _tickTimer() {
    _countdownTimer?.cancel();
    final isHost = ref.read(isHostProvider);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) return;
      final room = ref.read(roomControllerProvider).value;
      if (room == null) return;

      if (isHost) {
        // Host: Decrement and update shared room timer
        final nextTimer = (room.timer - 1).clamp(0, 999999).toInt();
        try {
          await ref.read(databaseServiceProvider).updateRoomFields(room.roomId, {'timer': nextTimer});
        } catch (_) {}
      }

      // All devices: Read from shared room timer
      if (!mounted) return;
      setState(() {
        _timeRemaining = room.timer;
        if (_timeRemaining <= 0) {
          _handlePhaseTransition();
        }
      });
    });
  }

  void _handlePhaseTransition() {
    final isHost = ref.read(isHostProvider);
    if (!isHost) {
      // Non-hosts don't auto-transition; wait for host to broadcast phase change
      return;
    }

    setState(() {
      if (_auctionPhase == 0) {
        _auctionPhase = 1;
        _timeRemaining = 3;
        _phaseText = 'GOING ONCE';
        _broadcastPhaseChange('GOING ONCE', 3);
      } else if (_auctionPhase == 1) {
        _auctionPhase = 2;
        _timeRemaining = 3;
        _phaseText = 'GOING TWICE';
        _broadcastPhaseChange('GOING TWICE', 3);
      } else if (_auctionPhase == 2) {
        _auctionPhase = 3;
        _phaseText = 'SOLD!';
        _countdownTimer?.cancel();
        _broadcastPhaseChange('SOLD!', 0);
        Future.delayed(const Duration(seconds: 2), () => _handleAutoMove(true, null));
        return;
      }
    });
    _tickTimer();
  }

  Future<void> _broadcastPhaseChange(String phaseText, int timerValue) async {
    final room = ref.read(roomControllerProvider).value;
    if (room == null) return;
    try {
      await ref.read(databaseServiceProvider).updateRoomFields(room.roomId, {
        'timer': timerValue,
        'auctionPhase': _auctionPhase,
      });
    } catch (_) {}
  }

  Future<void> _syncRoomTimer(int timerValue) async {
    final room = ref.read(roomControllerProvider).value;
    if (room == null) return;
    try {
      await ref.read(databaseServiceProvider).updateRoomFields(room.roomId, {
        'timer': timerValue,
        'auctionPhase': _auctionPhase,
      });
    } catch (_) {}
  }

  void _handleAutoMove(bool sold, List<RoomPlayerModel>? roomPlayers) {
    final playersAsync = ref.read(playersProvider);
    playersAsync.whenData((players) {
      _moveToNextPlayer(players, roomPlayers);
    });
  }

  Future<void> _recordCurrentResult(PlayerModel player, RoomModel? room, List<RoomPlayerModel>? roomPlayers) async {
    if (room == null) return;
    
    // Query actual bids from database for this player
    final auction = await ref.read(databaseServiceProvider).getAuctionForRoom(room.roomId);
    if (auction == null) return;
    
    final playerBids = await ref.read(databaseServiceProvider).getBidsForPlayer(auction.id, player.name);
    final hasBids = playerBids.isNotEmpty;
    
    final highestBid = hasBids ? playerBids.map((b) => b.bidAmount).reduce((a, b) => a > b ? a : b) : 0;
    final winnerBid = hasBids ? playerBids.first : null;
    final winnerName = winnerBid?.username ?? 'Unknown';
    
    final bidderTeam = hasBids && roomPlayers != null
        ? (roomPlayers.firstWhere(
            (p) => p.username == winnerName,
            orElse: () => roomPlayers.first,
          ).teamName ?? 'TBD')
        : null;

    // Mark as SOLD only if there were actual bids placed
    final isSold = hasBids;

    _auctionResults.removeWhere((entry) => entry['name'] == player.name);
    _auctionResults.add({
      'name': player.name,
      'role': player.role,
      'isForeign': player.isForeign,
      'basePrice': player.basePrice,
      'status': isSold ? 'sold' : 'unsold',
      'soldToTeam': isSold ? bidderTeam : null,
      'soldPrice': isSold ? highestBid : 0,
      'winnerName': isSold ? winnerName : null,
    });
  }

  Future<void> _placeBid(int amount, List<RoomPlayerModel>? roomPlayers) async {
    if (_placingBid) return;
    _placingBid = true;
    try {
      final room = ref.read(roomControllerProvider).value;
      if (room == null) return;

      await ref.read(roomControllerProvider.notifier).placeBid(amount);

      setState(() {
        _timeRemaining = AppConstants.initialAuctionTimer;
        _auctionPhase = 0;
        _phaseText = 'Place your bids';
      });
      await _syncRoomTimer(AppConstants.initialAuctionTimer);
      _tickTimer();

      final session = ref.read(sessionControllerProvider);
      final bid = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'bidderName': session.user?.username ?? 'Unknown',
        'teamCode': roomPlayers == null || roomPlayers.isEmpty
            ? 'TBD'
            : (roomPlayers.firstWhere(
                (player) => player.username == (session.user?.username ?? ''),
                orElse: () => roomPlayers.first,
              ).teamName ?? 'TBD'),
        'amount': amount,
        'timestamp': DateTime.now(),
      };

      setState(() {
        _lastFiveBids.insert(0, bid);
        if (_lastFiveBids.length > 5) _lastFiveBids.removeLast();
        
        final bidderName = session.user?.username ?? 'Unknown';
        _playerBidTotal[bidderName] = (_playerBidTotal[bidderName] ?? 0) + amount;
      });

      _bidController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bid failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      _placingBid = false;
    }
  }

  Future<void> _moveToNextPlayer(List<PlayerModel> players, List<RoomPlayerModel>? roomPlayers) async {
    final room = ref.read(roomControllerProvider).value;
    if (_currentIndex < players.length) {
      await _recordCurrentResult(players[_currentIndex], room, roomPlayers);
    }

    if (_currentIndex < players.length - 1) {
      setState(() {
        _currentIndex += 1;
        _lastFiveBids.clear();
      });
      _startTimerPhase();

      try {
        final room = ref.read(roomControllerProvider).value;
        if (room != null && mounted) {
          await ref.read(roomControllerProvider.notifier).nextPlayer(sold: _phaseText == 'SOLD!');
        }
      } catch (e) {
        print('Error advancing player: $e');
      }
      return;
    }

    try {
      if (mounted) {
        await ref.read(roomControllerProvider.notifier).updateRoomStatus(RoomStatus.completed);
        if (!context.mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
        );
      }
    } catch (e) {
      print('Error completing auction: $e');
    }
  }

  void _handleSold(List<PlayerModel> players, List<RoomPlayerModel>? roomPlayers) async {
    final room = ref.read(roomControllerProvider).value;
    if (room == null) return;
    
    setState(() {
      _phaseText = 'SOLD!';
      _auctionPhase = 3;
    });
    _countdownTimer?.cancel();
    
    // Broadcast to all devices
    try {
      await ref.read(databaseServiceProvider).updateRoomFields(room.roomId, {
        'auctionPhase': 3,
        'timer': 0,
      });
    } catch (_) {}
    
    Future.delayed(const Duration(seconds: 2), () => _moveToNextPlayer(players, roomPlayers));
  }

  void _handleUnsold(List<PlayerModel> players, List<RoomPlayerModel>? roomPlayers) async {
    final room = ref.read(roomControllerProvider).value;
    if (room == null) return;
    
    setState(() {
      _phaseText = 'UNSOLD';
      _auctionPhase = 3;
    });
    _countdownTimer?.cancel();
    
    // Broadcast to all devices
    try {
      await ref.read(databaseServiceProvider).updateRoomFields(room.roomId, {
        'auctionPhase': 3,
        'timer': 0,
      });
    } catch (_) {}
    
    Future.delayed(const Duration(seconds: 2), () => _moveToNextPlayer(players, roomPlayers));
  }

  Widget _buildTopPlayerCard(PlayerModel? player, RoomModel? room) {
    final highest = room?.highestBid ?? 0;
    final highestBidder = _lastFiveBids.isNotEmpty 
        ? _lastFiveBids.first['bidderName'] as String
        : 'No bids yet';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [const Color(0xFF1E40AF), const Color(0xFF0C2D57)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.amber.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PlayerImage(url: player?.imageUrl ?? '', size: 120),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player?.name ?? 'No Player',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.amber.withOpacity(0.2),
                        border: Border.all(color: Colors.amber),
                      ),
                      child: Text(
                        player?.role ?? '',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Country',
                                style: TextStyle(fontSize: 11, color: Colors.white70),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                player?.country ?? 'N/A',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Base Price',
                                style: TextStyle(fontSize: 11, color: Colors.white70),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '₹${player?.basePrice ?? 0}L',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.lime,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white12),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildBidInfoCard('Current Bid', '₹$highest L', Colors.amber),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBidInfoCard('Bidder', highestBidder, Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBidInfoCard(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
          const SizedBox(height: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              value,
              key: ValueKey(value),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerSection(RoomModel? room, List<PlayerModel> players, List<RoomPlayerModel>? roomPlayers) {
    final isHost = ref.watch(isHostProvider);
    final sharedTimer = room?.timer ?? _timeRemaining;
    final color = _auctionPhase == 3 ? Colors.green : (_auctionPhase > 0 ? Colors.orange : Colors.amber);

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [const Color(0xFF1F2937), const Color(0xFF111827)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: color.withOpacity(0.5), width: 2),
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.2), blurRadius: 15),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Auction Timer', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.timer, color: color, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      '$sharedTimer s',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _phaseText,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        if (isHost)
          Expanded(
            child: Column(
              children: [
                Wrap(spacing: 6, children: [
                  _buildHostButton('Once', () async {
                    setState(() {
                      _auctionPhase = 1;
                      _timeRemaining = 3;
                      _phaseText = 'GOING ONCE';
                    });
                    await _broadcastPhaseChange('GOING ONCE', 3);
                    _tickTimer();
                  }),
                  _buildHostButton('Twice', () async {
                    setState(() {
                      _auctionPhase = 2;
                      _timeRemaining = 3;
                      _phaseText = 'GOING TWICE';
                    });
                    await _broadcastPhaseChange('GOING TWICE', 3);
                    _tickTimer();
                  }),
                ]),
                const SizedBox(height: 8),
                Wrap(spacing: 6, children: [
                  _buildHostButton('✓ Sold', () => _handleSold(players, roomPlayers), success: true),
                  _buildHostButton('✗ Unsold', () => _handleUnsold(players, roomPlayers), warning: true),
                ]),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildHostButton(String label, VoidCallback onTap, {bool success = false, bool warning = false}) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      backgroundColor: success ? Colors.green.withOpacity(0.2)
          : warning ? Colors.red.withOpacity(0.2)
          : Colors.blue.withOpacity(0.2),
      side: BorderSide(
        color: success ? Colors.green
            : warning ? Colors.red
            : Colors.blue,
      ),
      onPressed: onTap,
    );
  }

  Widget _buildBidControls(RoomModel? room, List<PlayerModel>? players, {List<RoomPlayerModel>? roomPlayers}) {
    final currentPlayer = players != null && _currentIndex < players.length ? players[_currentIndex] : null;
    final basePrice = currentPlayer?.basePrice ?? 0;
    final currentHighest = room?.highestBid ?? 0;
    // If no bids yet (highestBid is 0), start from base price. Otherwise add 10 to current bid
    final nextBid = currentHighest == 0 ? basePrice : currentHighest + 10;
    final isHost = ref.watch(isHostProvider);
    final room_hostMode = room?.hostMode;

    final canBid = !isHost || (room_hostMode == 'play');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [const Color(0xFF1F2937), const Color(0xFF111827)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (canBid) ...[
            // Show minimum bid hint (base price or last bid + 10)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.blue.withOpacity(0.1),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _lastFiveBids.isEmpty
                          ? 'First bid starts at ₹$basePrice L (base price)'
                          : 'Minimum bid: ₹$nextBid L',
                      style: const TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _bidController,
                    keyboardType: TextInputType.number,
                    enabled: !_placingBid,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'Enter bid (₹L)',
                      prefixText: '₹',
                      suffixText: 'L',
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                NeonButton(
                  label: _placingBid ? 'Bidding...' : 'Bid',
                  icon: Icons.gavel,
                  onTap: _placingBid ? null : () async {
                    final bidAmount = _bidController.text.trim().isEmpty ? nextBid : int.tryParse(_bidController.text.trim()) ?? nextBid;
                    // Validate: must be at least nextBid
                    if (bidAmount < nextBid) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Bid must be at least ₹$nextBid L'), backgroundColor: Colors.red),
                      );
                      _placingBid = false;
                      return;
                    }
                    final amount = bidAmount;
                    await _placeBid(amount, roomPlayers);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_lastFiveBids.isEmpty)
                  _buildPresetBidButton('Base (₹$basePrice L)', basePrice, roomPlayers)
                else
                  _buildPresetBidButton('Bid ₹$nextBid L', nextBid, roomPlayers),
                _buildPresetBidButton('+50L', (room?.highestBid ?? 0) + 50, roomPlayers),
                _buildPresetBidButton('+100L', (room?.highestBid ?? 0) + 100, roomPlayers),
              ],
            ),
          ] else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.blue.withOpacity(0.1),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.admin_panel_settings, color: Colors.blue),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Conducting Mode',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'You are conducting only • Cannot bid',
                          style: TextStyle(color: Colors.blue, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPresetBidButton(String label, int amount, List<RoomPlayerModel>? roomPlayers) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: Colors.amber.withOpacity(0.2),
      side: const BorderSide(color: Colors.amber),
      onPressed: _placingBid ? null : () => _placeBid(amount, roomPlayers),
    );
  }

  Widget _buildLastFiveBids() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [const Color(0xFF1F2937), const Color(0xFF111827)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Latest Bids',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              const Spacer(),
              Text(
                '${_lastFiveBids.length}/5',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: _lastFiveBids.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.hourglass_empty, color: Colors.white30, size: 32),
                        const SizedBox(height: 8),
                        const Text('No bids yet', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: _lastFiveBids.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final bid = _lastFiveBids[i];
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: i == 0
                              ? Colors.amber.withOpacity(0.15)
                              : Colors.white.withOpacity(0.05),
                          border: Border.all(
                            color: i == 0 ? Colors.amber.withOpacity(0.5) : Colors.white10,
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.amber.withOpacity(0.2),
                              child: Text(
                                bid['teamCode']?[0] ?? bid['bidderName'][0],
                                style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.amber),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bid['bidderName'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    bid['teamCode'] ?? '',
                                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹${bid['amount']}L',
                                  style: const TextStyle(
                                    color: Colors.lime,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
                                ),
                                const Text(
                                  'bid',
                                  style: TextStyle(fontSize: 10, color: Colors.white70),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyStats(RoomModel? room, List<RoomPlayerModel>? roomPlayers) {
    final uid = ref.read(sessionControllerProvider).uid;
    final session = ref.read(sessionControllerProvider);
    final myTotalSpent = _playerBidTotal[session.user?.username ?? ''] ?? 0;
    
    if (uid == null || roomPlayers == null) {
      return const SizedBox.shrink();
    }

    final myPlayer = roomPlayers.firstWhere((p) => p.userId == uid, orElse: () => roomPlayers.first);
    final purseRemaining = (myPlayer.budget - myTotalSpent).clamp(0, myPlayer.budget);

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [const Color(0xFF10B981), const Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Purse Remaining', style: TextStyle(fontSize: 11, color: Colors.white70)),
                const SizedBox(height: 6),
                Text(
                  '₹$purseRemaining L',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [const Color(0xFFEF4444), const Color(0xFFDC2626)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Spent', style: TextStyle(fontSize: 11, color: Colors.white70)),
                const SizedBox(height: 6),
                Text(
                  '₹$myTotalSpent L',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final roomAsync = ref.watch(roomControllerProvider);
    final playersAsync = ref.watch(playersProvider);
    final playersStream = ref.watch(realtimeServiceProvider).subscribeToRoomPlayers(
      roomAsync.value?.roomId ?? '',
      () => ref.read(databaseServiceProvider).getRoomPlayers(roomAsync.value?.roomId ?? ''),
    );

    final bidsStream = roomAsync.value != null
        ? ref.watch(realtimeServiceProvider).subscribeToBids(
              roomAsync.value!.roomId,
              () async {
                final database = ref.read(databaseServiceProvider);
                final auction = await database.getAuctionForRoom(roomAsync.value!.roomId);
                if (auction == null) return [];
                final bids = await database.getBidsForAuction(auction.id);
                return bids.take(5).map((bid) {
                  return {
                    'id': bid.id,
                    'bidderName': bid.username,
                    'amount': bid.bidAmount,
                    'timestamp': bid.timestamp ?? DateTime.now(),
                    'playerName': bid.playerName,
                  };
                }).toList();
              },
            )
        : null;

    ref.listen(roomControllerProvider, (previous, next) {
      if (previous?.value != null && next.value == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _goHome());
      } else if (previous?.value != null && next.value != null) {
        // Sync phase and timer from room to local state
        final prevRoom = previous!.value;
        final nextRoom = next.value!;
        
        if (prevRoom!.timer != nextRoom.timer) {
          // Timer changed, update locally
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _timeRemaining = nextRoom.timer;
              });
            }
          });
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('🎯 Live Auction'),
        elevation: 0,
        backgroundColor: const Color(0xFF0F172A),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Chip(
                label: Text('${_currentIndex + 1}/${playersAsync.value?.length ?? 0}'),
                avatar: const Icon(Icons.sports_cricket, size: 18),
              ),
            ),
          ),
        ],
      ),
      body: playersAsync.when(
        data: (players) {
          return roomAsync.when(
            data: (room) {
              if (room == null) {
                return const Center(child: Text('Room missing'));
              }

              if (_currentIndex >= players.length) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [const Color(0xFF10B981), const Color(0xFF059669)],
                          ),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.check_circle, size: 64, color: Colors.white),
                            SizedBox(height: 16),
                            Text(
                              'Auction Complete!',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () async {
                          await ref.read(roomControllerProvider.notifier).updateRoomStatus(RoomStatus.completed);
                          if (!context.mounted) return;
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
                          );
                        },
                        icon: const Icon(Icons.emoji_events),
                        label: const Text('View Final Summary'),
                      ),
                    ],
                  ),
                );
              }

              final currentPlayer = players[_currentIndex];

              return StreamBuilder<List<RoomPlayerModel>>(
                stream: playersStream,
                builder: (context, snapshot) {
                  final roomPlayers = snapshot.data;
                  final sessionUser = ref.read(sessionControllerProvider).user?.username ?? '';
                  
                  return StreamBuilder<List<Map<String, dynamic>>>(
                    stream: bidsStream,
                    builder: (context, bidsSnapshot) {
                      // Update local bids list when stream emits new data
                      if (bidsSnapshot.hasData && bidsSnapshot.data != null) {
                        final newBids = bidsSnapshot.data!;
                        if (newBids.isNotEmpty) {
                          // Create a cache key to detect actual changes
                          final cacheKey = newBids
                              .map((b) => '${b['id']}:${b['amount']}')
                              .join('|');
                          
                          if (cacheKey != _lastBidsCacheKey) {
                            // Enrich bids with team info from roomPlayers
                            final enrichedBids = newBids.map((bid) {
                              String teamCode = 'TBD';
                              if (roomPlayers != null && roomPlayers.isNotEmpty) {
                                final bidder = roomPlayers.firstWhere(
                                  (p) => p.username == bid['bidderName'],
                                  orElse: () => roomPlayers.first,
                                );
                                teamCode = bidder.teamName ?? 'TBD';
                              }
                              return {
                                ...bid,
                                'teamCode': teamCode,
                              };
                            }).toList();
                            
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                setState(() {
                                  _lastBidsCacheKey = cacheKey;
                                  _lastFiveBids.clear();
                                  _lastFiveBids.addAll(enrichedBids);
                                });
                              }
                            });
                          }
                        }
                      }

                      return SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildTopPlayerCard(currentPlayer, room),
                              const SizedBox(height: 16),
                              _buildTimerSection(room, players, roomPlayers),
                              const SizedBox(height: 16),
                              _buildBidControls(room, players, roomPlayers: roomPlayers),
                              const SizedBox(height: 16),
                              _buildMyStats(room, roomPlayers),
                              const SizedBox(height: 16),
                              _buildLastFiveBids(),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: FilledButton.icon(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => AllPlayersTableScreen(
                                          players: players,
                                          auctionResults: _auctionResults,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.table_view),
                                  label: const Text('All Players Table'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => MyBuysScreen(
                                          players: _auctionResults
                                              .where((entry) => entry['status'] == 'sold' && entry['winnerName'] == sessionUser)
                                              .toList(),
                                          teamName: () {
                                            if (roomPlayers == null || roomPlayers.isEmpty) {
                                              return '';
                                            }
                                            final matchingPlayers = roomPlayers.where((player) => player.username == sessionUser).toList();
                                            return (matchingPlayers.isNotEmpty ? matchingPlayers.first.teamName : roomPlayers.first.teamName) ?? '';
                                          }(),
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.shopping_bag),
                                  label: const Text('My Bought Players'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                colors: [const Color(0xFF1F2937), const Color(0xFF111827)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.list, color: Colors.amber, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Players Queue',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 200,
                                  child: ListView.separated(
                                    itemBuilder: (_, index) {
                                      final p = players[index];
                                      final isCurrent = index == _currentIndex;
                                      final isProcessed = index < _currentIndex;
                                      return Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          color: isCurrent
                                              ? Colors.amber.withOpacity(0.15)
                                              : isProcessed
                                                  ? Colors.green.withOpacity(0.1)
                                                  : Colors.white.withOpacity(0.03),
                                          border: Border.all(
                                            color: isCurrent
                                                ? Colors.amber.withOpacity(0.5)
                                                : Colors.white10,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: isCurrent
                                                  ? Colors.amber
                                                  : isProcessed
                                                      ? Colors.green
                                                      : Colors.white10,
                                              child: Text(
                                                '${index + 1}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  color: isCurrent || isProcessed ? Colors.white : Colors.white30,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    p.name,
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 13,
                                                      color: isCurrent ? Colors.amber : Colors.white,
                                                    ),
                                                  ),
                                                  Text(
                                                    '${p.role} • ₹${p.basePrice}L',
                                                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (isCurrent)
                                              const Icon(Icons.play_arrow, color: Colors.amber)
                                            else if (isProcessed)
                                              const Icon(Icons.check_circle, color: Colors.green, size: 18),
                                          ],
                                        ),
                                      );
                                    },
                                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                                    itemCount: players.length,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ));
                    },
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(e.toString())),
          );
        },
        loading: () => const ShimmerPlayerList(),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Failed to load players: $e'),
              TextButton(
                onPressed: () => ref.refresh(playersProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
