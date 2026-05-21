import 'package:flutter/material.dart';
import 'package:ipl_auction_game/parameters.dart';
import 'package:ipl_auction_game/models.dart';

class TeamOverviewPage extends StatefulWidget {
  final List<GameTeam> teams;
  final VoidCallback? onContinue;
  final String? currentPlayerName;
  const TeamOverviewPage({
    super.key,
    required this.teams,
    this.onContinue,
    this.currentPlayerName,
  });

  @override
  State<TeamOverviewPage> createState() => _TeamOverviewPageState();
}

class _TeamOverviewPageState extends State<TeamOverviewPage> {
  Set<int> expandedTeams = {};

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final hei = size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: iconPurple.withAlpha(250),
        title: Text(
          'Teams Overview',
          style: TextStyle(color: iconGold, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back, color: iconGold),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                'ALL TEAMS STATUS',
                style: TextStyle(
                  color: iconGold,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              SizedBox(height: hei * 0.02),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: widget.teams.length,
                itemBuilder: (ctx, idx) {
                  final team = widget.teams[idx];
                  final isExpanded = expandedTeams.contains(idx);
                  final isMyTeam =
                      widget.currentPlayerName != null &&
                      team.playerName == widget.currentPlayerName;

                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: Colors.transparent,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors:
                              isMyTeam
                                  ? [
                                    iconGold.withAlpha(150),
                                    iconGold.withAlpha(80),
                                  ]
                                  : [
                                    iconPurple.withAlpha(200),
                                    iconPurple.withAlpha(150),
                                  ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isMyTeam ? iconGold : iconGold.withAlpha(100),
                          width: isMyTeam ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                if (isExpanded) {
                                  expandedTeams.remove(idx);
                                } else {
                                  expandedTeams.add(idx);
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: iconGold.withAlpha(150),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            team.teamName
                                                .substring(0, 2)
                                                .toUpperCase(),
                                            style: TextStyle(
                                              color: iconPurple,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                if (isMyTeam) ...[
                                                  Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: iconPurple,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      'YOU',
                                                      style: TextStyle(
                                                        color: iconGold,
                                                        fontSize: 9,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(width: 6),
                                                ],
                                                Expanded(
                                                  child: Text(
                                                    team.teamName,
                                                    style: TextStyle(
                                                      color: iconGold,
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              team.playerName,
                                              style: TextStyle(
                                                color: iconGold.withAlpha(180),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        isExpanded
                                            ? Icons.expand_less
                                            : Icons.expand_more,
                                        color: iconGold,
                                        size: 30,
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildStatColumn(
                                        'Budget',
                                        '₹${team.totalBudget}L',
                                        iconGold.withAlpha(200),
                                      ),
                                      _buildStatColumn(
                                        'Spent',
                                        '₹${team.spent}L',
                                        Colors.redAccent,
                                      ),
                                      _buildStatColumn(
                                        'Remaining',
                                        '₹${team.remaining}L',
                                        Colors.greenAccent,
                                      ),
                                      _buildStatColumn(
                                        'Players',
                                        '${team.playersCount}',
                                        Colors.blueAccent,
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: team.spent / team.totalBudget,
                                      minHeight: 8,
                                      backgroundColor: Colors.grey.withAlpha(
                                        100,
                                      ),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        team.remaining > 2000
                                            ? iconGold
                                            : Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (isExpanded && team.players.isNotEmpty) ...[
                            Divider(
                              color: iconGold.withAlpha(100),
                              thickness: 1,
                            ),
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'SQUAD ROSTER',
                                    style: TextStyle(
                                      color: iconGold,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  // Table Header
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: iconGold.withAlpha(100),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                            'PLAYER NAME',
                                            style: TextStyle(
                                              color: iconPurple,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'ROLE',
                                          style: TextStyle(
                                            color: iconPurple,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          flex: 1,
                                          child: Text(
                                            'TYPE',
                                            style: TextStyle(
                                              color: iconPurple,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          flex: 1,
                                          child: Text(
                                            'PRICE',
                                            textAlign: TextAlign.right,
                                            style: TextStyle(
                                              color: iconPurple,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  // Table Rows
                                  ...team.players.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final player = entry.value;
                                    return Container(
                                      margin: EdgeInsets.only(bottom: 6),
                                      padding: EdgeInsets.symmetric(
                                        vertical: 10,
                                        horizontal: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withAlpha(100),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: iconGold.withAlpha(50),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              color: iconGold.withAlpha(150),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Text(
                                                '${index + 1}',
                                                style: TextStyle(
                                                  color: iconPurple,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Expanded(
                                            flex: 3,
                                            child: Text(
                                              player.name,
                                              style: TextStyle(
                                                color: iconGold,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          _buildRoleIcon(player.role),
                                          SizedBox(width: 8),
                                          Expanded(
                                            flex: 1,
                                            child:
                                                player.isForeign
                                                    ? Icon(
                                                      Icons.flight_takeoff,
                                                      color: Colors.blueAccent,
                                                      size: 18,
                                                    )
                                                    : Icon(
                                                      Icons.home,
                                                      color: Colors.greenAccent,
                                                      size: 18,
                                                    ),
                                          ),
                                          SizedBox(width: 8),
                                          Expanded(
                                            flex: 1,
                                            child: Text(
                                              '₹${player.cost}L',
                                              textAlign: TextAlign.right,
                                              style: TextStyle(
                                                color: Colors.greenAccent,
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  SizedBox(height: 8),
                                  // Foreign Players Count
                                  Container(
                                    padding: EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withAlpha(50),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.blueAccent.withAlpha(100),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.flight_takeoff,
                                              color: Colors.blueAccent,
                                              size: 18,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Foreign Players',
                                              style: TextStyle(
                                                color: iconGold,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          '${team.foreignPlayersCount} / 4',
                                          style: TextStyle(
                                            color:
                                                team.foreignPlayersCount >= 4
                                                    ? Colors.red
                                                    : Colors.greenAccent,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else if (isExpanded && team.players.isEmpty) ...[
                            Divider(
                              color: iconGold.withAlpha(100),
                              thickness: 1,
                            ),
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                child: Text(
                                  'No players bought yet',
                                  style: TextStyle(
                                    color: iconGold.withAlpha(150),
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
              if (widget.onContinue != null) ...[
                SizedBox(height: hei * 0.03),
                ElevatedButton(
                  onPressed: widget.onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: iconGreen,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_arrow, color: iconGold),
                      SizedBox(width: 8),
                      Text(
                        'Continue Auction',
                        style: TextStyle(
                          color: iconGold,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: iconGold.withAlpha(150),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleIcon(String role) {
    IconData icon;
    Color color;

    if (role.toLowerCase().contains('wk')) {
      // WK-Batsman
      icon = Icons.sports_handball; // Glove icon for wicket keeper
      color = Colors.blue;
    } else if (role.toLowerCase().contains('bat')) {
      icon = Icons.sports_cricket;
      color = Colors.orange;
    } else if (role.toLowerCase().contains('bowl')) {
      icon = Icons.sports_baseball;
      color = Colors.red;
    } else {
      // All-rounder
      icon = Icons.stars;
      color = Colors.amber;
    }

    return Icon(icon, color: color, size: 18);
  }
}
