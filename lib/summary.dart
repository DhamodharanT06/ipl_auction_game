import 'package:flutter/material.dart';
import 'package:ipl_auction_game/parameters.dart';
import 'package:ipl_auction_game/homepage.dart';
import 'package:ipl_auction_game/models.dart';

class SummaryPage extends StatefulWidget {
  final List<GameTeam> teams;
  const SummaryPage({super.key, required this.teams});

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final hei = size.height;
    
    // Sort teams by total spent (highest first)
    final sortedTeams = List<GameTeam>.from(widget.teams)
      ..sort((a, b) => b.spent.compareTo(a.spent));

    return Scaffold(
      backgroundColor: iconGreen.withAlpha(100),
      appBar: AppBar(
        backgroundColor: iconGreen.withAlpha(100),
        title: Text(
          '🏆 Auction Complete',
          style: TextStyle(color: iconGold, fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'Final Results',
                  style: TextStyle(
                    color: iconGold,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: hei * 0.03),

                // Leaderboard
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: sortedTeams.length,
                  itemBuilder: (ctx, idx) {
                    final team = sortedTeams[idx];
                    final rank = idx + 1;
                    final isWinner = rank == 1;

                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 12),
                      elevation: isWinner ? 12 : 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: isWinner
                              ? LinearGradient(
                                  colors: [Colors.amber.withAlpha(200), iconGold.withAlpha(200)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: isWinner ? null : iconPurple.withAlpha(180),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isWinner ? iconGold : Colors.grey,
                            width: isWinner ? 2 : 1,
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (isWinner)
                                    TweenAnimationBuilder<double>(
                                      tween: Tween(begin: 0.8, end: 1.0),
                                      duration: Duration(milliseconds: 1000),
                                      curve: Curves.elasticOut,
                                      builder: (context, scale, child) {
                                        return Transform.scale(
                                          scale: scale,
                                          child: Icon(Icons.emoji_events, color: Colors.amber, size: 36),
                                        );
                                      },
                                    ),
                                  if (isWinner) SizedBox(width: 8),
                                  Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isWinner ? iconGold : Colors.grey,
                                  ),
                                  child: Center(
                                    child: isWinner
                                        ? Icon(Icons.star, color: iconPurple, size: 24)
                                        : Text(
                                            '$rank',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        team.playerName,
                                        style: TextStyle(
                                          color: isWinner ? iconPurple : iconGold,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Squad: ${team.players.length} players',
                                        style: TextStyle(
                                          color: isWinner
                                              ? iconPurple.withAlpha(180)
                                              : iconGold.withAlpha(150),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '₹ ${team.spent} L',
                                      style: TextStyle(
                                        color: isWinner ? iconPurple : Colors.greenAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      'Total Spent',
                                      style: TextStyle(
                                        color: isWinner
                                            ? iconPurple.withAlpha(180)
                                            : iconGold.withAlpha(150),
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            if (team.players.isNotEmpty)
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isWinner ? iconPurple.withAlpha(100) : Colors.grey.withAlpha(100),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Wrap(
                                  spacing: 8,
                                  children: team.players.map((player) {
                                    return Chip(
                                      label: Text('${player.name} (${player.cost}L)', style: TextStyle(fontSize: 11)),
                                      backgroundColor: isWinner ? iconGold.withAlpha(200) : Colors.transparent,
                                      side: BorderSide(
                                        color: isWinner ? iconGold : iconGold.withAlpha(100),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: hei * 0.05),

                // Action Buttons
                Wrap(
                  spacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) => Homepage(),
                            transitionDuration: Duration.zero,
                            reverseTransitionDuration: Duration.zero,
                            transitionsBuilder: (_, __, ___, child) => child,
                          ),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: iconGreen,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        'New Game',
                        style: TextStyle(color: iconGold, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        'Exit',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
