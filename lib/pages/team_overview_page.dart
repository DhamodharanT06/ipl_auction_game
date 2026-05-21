import 'package:flutter/material.dart';
import '../parameters.dart';
import '../models/game_models.dart';

class TeamOverviewPage extends StatefulWidget {
  final List<RoomPlayer> teams;
  final String? currentPlayerName;

  const TeamOverviewPage({
    super.key,
    required this.teams,
    this.currentPlayerName,
  });

  @override
  State<TeamOverviewPage> createState() => _TeamOverviewPageState();
}

class _TeamOverviewPageState extends State<TeamOverviewPage> {
  String? _expandedTeam;

  @override
  Widget build(BuildContext context) {
    // Sort teams by total spent (descending)
    final sortedTeams = List<RoomPlayer>.from(widget.teams)
      ..sort((a, b) => _calculateSpent(b).compareTo(_calculateSpent(a)));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: iconPurple.withAlpha(200),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: iconGold),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Team Overview',
          style: TextStyle(
            color: iconGold,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sortedTeams.length,
        itemBuilder: (context, index) => _buildTeamCard(sortedTeams[index], index),
      ),
    );
  }

  int _calculateSpent(RoomPlayer player) {
    int spent = 0;
    for (final p in player.playersOwned) {
      spent += (p['cost'] as int?) ?? 0;
    }
    return spent;
  }

  Widget _buildTeamCard(RoomPlayer team, int rank) {
    final isExpanded = _expandedTeam == team.username;
    final totalSpent = _calculateSpent(team);
    final isCurrentPlayer = team.username == widget.currentPlayerName;

    // Categorize players by role
    final batsmen = team.playersOwned.where((p) => (p['role'] ?? '').toLowerCase() == 'batsman').toList();
    final bowlers = team.playersOwned.where((p) => (p['role'] ?? '').toLowerCase() == 'bowler').toList();
    final allRounders = team.playersOwned.where((p) => (p['role'] ?? '').toLowerCase() == 'all-rounder').toList();
    // ignore: unused_local_variable
    final wicketkeepers = team.playersOwned.where((p) => (p['role'] ?? '').toLowerCase().contains('wicket')).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            iconGold.withAlpha(rank == 0 ? 100 : 50),
            iconPurple.withAlpha(150),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentPlayer ? iconGold : iconGold.withAlpha(50),
          width: isCurrentPlayer ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // Team Header
          InkWell(
            onTap: () {
              setState(() {
                _expandedTeam = isExpanded ? null : team.username;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Rank Badge
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: rank == 0 
                              ? iconGold 
                              : rank == 1 
                                  ? Colors.grey.shade400 
                                  : rank == 2 
                                      ? Colors.brown.shade400 
                                      : Colors.grey.withAlpha(100),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '#${rank + 1}',
                            style: TextStyle(
                              color: rank < 3 ? Colors.black : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Team Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (team.isHost)
                                  Icon(Icons.star, color: iconGold, size: 18),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    team.username,
                                    style: TextStyle(
                                      color: iconGold,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isCurrentPlayer)
                                  Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: iconGold,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      'YOU',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              team.teamName.isEmpty ? 'No Team Selected' : team.teamName,
                              style: TextStyle(
                                color: iconGold.withAlpha(180),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Expand Icon
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: iconGold,
                        size: 28,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Budget Progress
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Remaining: ₹${team.budget}L',
                            style: TextStyle(
                              color: team.budget > 200 ? Colors.greenAccent : Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Spent: ₹${totalSpent}L',
                            style: TextStyle(
                              color: iconGold.withAlpha(180),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: totalSpent / 1000,
                          backgroundColor: Colors.grey.withAlpha(100),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            totalSpent > 800 ? Colors.redAccent : Colors.greenAccent,
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Player Count Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildCountChip('Players', team.playersOwned.length.toString(), iconGold),
                      _buildCountChip('Batsmen', batsmen.length.toString(), Colors.blue),
                      _buildCountChip('Bowlers', bowlers.length.toString(), Colors.red),
                      _buildCountChip('AR', allRounders.length.toString(), Colors.purple),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Expanded Squad Roster
          if (isExpanded) ...[
            Divider(color: iconGold.withAlpha(50), height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SQUAD ROSTER',
                    style: TextStyle(
                      color: iconGold,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (team.playersOwned.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'No players acquired yet',
                          style: TextStyle(color: iconGold.withAlpha(150)),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: [
                        // Header Row
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: iconGold.withAlpha(30),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'Player',
                                  style: TextStyle(
                                    color: iconGold,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Role',
                                  style: TextStyle(
                                    color: iconGold,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  'Price',
                                  style: TextStyle(
                                    color: iconGold,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Player Rows
                        ...team.playersOwned.map((player) => Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(50),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Row(
                                  children: [
                                    if (player['isForeign'] == true)
                                      Container(
                                        margin: const EdgeInsets.only(right: 6),
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withAlpha(100),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Text('🌍', style: TextStyle(fontSize: 10)),
                                      ),
                                    Flexible(
                                      child: Text(
                                        player['name'] ?? 'Unknown',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  player['role'] ?? 'Unknown',
                                  style: TextStyle(
                                    color: _getRoleColor(player['role'] ?? ''),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  '₹${player['cost'] ?? 0}L',
                                  style: const TextStyle(
                                    color: Colors.greenAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCountChip(String label, String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color.withAlpha(180),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'batsman':
        return Colors.blue;
      case 'bowler':
        return Colors.red;
      case 'all-rounder':
        return Colors.purple;
      case 'wicket-keeper':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
