import 'package:flutter/material.dart';
import 'package:ipl_auction_game/models/player_model.dart';

class AllPlayersTableScreen extends StatefulWidget {
  const AllPlayersTableScreen({
    super.key,
    required this.players,
    required this.auctionResults,
  });

  final List<PlayerModel> players;
  final List<Map<String, dynamic>> auctionResults;

  @override
  State<AllPlayersTableScreen> createState() => _AllPlayersTableScreenState();
}

class _AllPlayersTableScreenState extends State<AllPlayersTableScreen> {
  String _filterStatus = 'all'; // all, sold, unsold, pending

  Map<String, dynamic>? _resultFor(String name) {
    for (final entry in widget.auctionResults) {
      if (entry['name'] == name) return entry;
    }
    return null;
  }

  List<PlayerModel> _getFilteredPlayers() {
    return widget.players.where((player) {
      final result = _resultFor(player.name);
      final status = result?['status'] as String? ?? 'pending';
      if (_filterStatus == 'all') return true;
      return status == _filterStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredPlayers = _getFilteredPlayers();
    final totalSold = widget.auctionResults.where((e) => e['status'] == 'sold').length;
    final totalUnsold = widget.auctionResults.where((e) => e['status'] == 'unsold').length;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        title: const Text('All Players Table'),
        backgroundColor: const Color(0xFF111827),
      ),
      body: Column(
        children: [
          // Stats bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.white.withOpacity(0.02),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard('Total', widget.players.length.toString(), Colors.white70),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('Sold', totalSold.toString(), Colors.green),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('Unsold', totalUnsold.toString(), Colors.orange),
                ),
              ],
            ),
          ),
          // Filter buttons
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.white.withOpacity(0.04),
            child: Wrap(
              spacing: 8,
              children: [
                _buildFilterChip('All', 'all'),
                _buildFilterChip('Sold', 'sold'),
                _buildFilterChip('Unsold', 'unsold'),
              ],
            ),
          ),
          // Table header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            color: Colors.white.withOpacity(0.04),
            child: const Row(
              children: [
                Expanded(flex: 4, child: Text('NAME', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white70, fontSize: 12))),
                SizedBox(width: 12),
                SizedBox(width: 50, child: Text('ROLE', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white70, fontSize: 12), textAlign: TextAlign.center)),
                SizedBox(width: 12),
                SizedBox(width: 70, child: Text('BASE', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white70, fontSize: 12), textAlign: TextAlign.center)),
                SizedBox(width: 12),
                SizedBox(width: 80, child: Text('STATUS', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white70, fontSize: 12), textAlign: TextAlign.center)),
                SizedBox(width: 12),
                Expanded(flex: 2, child: Text('TEAM', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white70, fontSize: 12))),
              ],
            ),
          ),
          // Table rows
          Expanded(
            child: filteredPlayers.isEmpty
                ? Center(
                    child: Text(
                      'No players matching filter',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                : ListView.separated(
                    itemCount: filteredPlayers.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: Colors.white.withOpacity(0.06)),
                    itemBuilder: (context, index) {
                      final player = filteredPlayers[index];
                      final result = _resultFor(player.name);
                      final status = result?['status'] as String? ?? 'pending';
                      final team = result?['soldToTeam'] as String? ?? '-';
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                        decoration: BoxDecoration(
                          color: index % 2 == 0 ? Colors.white.withOpacity(0.01) : Colors.transparent,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: Row(
                                children: [
                                  if (player.isForeign)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 8),
                                      child: Icon(Icons.flight_takeoff, color: Colors.lightBlueAccent, size: 18),
                                    )
                                  else
                                    const Padding(
                                      padding: EdgeInsets.only(right: 8),
                                      child: Icon(Icons.location_on, color: Colors.grey, size: 18),
                                    ),
                                  Expanded(
                                    child: Text(
                                      player.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 50,
                              child: Text(
                                player.role,
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 70,
                              child: Text('₹${player.basePrice}L', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.w700, fontSize: 12), textAlign: TextAlign.center),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 80,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: status == 'sold' ? Colors.green.withOpacity(0.2) : status == 'unsold' ? Colors.orange.withOpacity(0.2) : Colors.white.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: status == 'sold' ? Colors.green : status == 'unsold' ? Colors.orange : Colors.white24),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    color: status == 'sold' ? Colors.greenAccent : status == 'unsold' ? Colors.orangeAccent : Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: Text(
                                team,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
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

  Widget _buildFilterChip(String label, String value) {
    final isActive = _filterStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isActive,
      onSelected: (selected) {
        setState(() => _filterStatus = value);
      },
      selectedColor: Colors.amber.withOpacity(0.3),
      backgroundColor: Colors.white.withOpacity(0.05),
      side: BorderSide(
        color: isActive ? Colors.amber : Colors.white24,
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
}
