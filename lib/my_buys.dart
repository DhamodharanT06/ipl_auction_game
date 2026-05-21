import 'package:flutter/material.dart';
import 'package:ipl_auction_game/parameters.dart';
import 'package:ipl_auction_game/models.dart';

class MyBuysPage extends StatelessWidget {
  final List<TeamPlayer> myPlayers;
  final String teamName;

  const MyBuysPage({super.key, required this.myPlayers, required this.teamName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: iconPurple.withAlpha(230),
        title: Text('My Bought Players • $teamName', style: TextStyle(color: iconGold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: iconGold.withAlpha(120),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(child: Text('PLAYER', style: TextStyle(color: iconPurple, fontWeight: FontWeight.bold))),
                  SizedBox(width: 12),
                  Text('BASE', style: TextStyle(color: iconPurple, fontWeight: FontWeight.bold)),
                  SizedBox(width: 24),
                  Text('BOUGHT', style: TextStyle(color: iconPurple, fontWeight: FontWeight.bold)),
                  SizedBox(width: 16),
                  SizedBox(width: 80, child: Text('ACTION', style: TextStyle(color: iconPurple, fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            SizedBox(height: 8),
            Expanded(
              child: myPlayers.isEmpty
                  ? Center(child: Text('No players bought yet', style: TextStyle(color: iconGold)))
                  : ListView.builder(
                      itemCount: myPlayers.length,
                      itemBuilder: (ctx, idx) {
                        final p = myPlayers[idx];
                        return Container(
                          margin: EdgeInsets.symmetric(vertical: 6),
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: iconPurple.withAlpha(120),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: iconGold.withAlpha(100)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    if (p.isForeign)
                                      Padding(
                                        padding: const EdgeInsets.only(right: 8.0),
                                        child: Icon(Icons.flight_takeoff, color: Colors.blueAccent, size: 18),
                                      ),
                                    Flexible(
                                      child: Text(p.name, style: TextStyle(color: iconGold, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('-', style: TextStyle(color: iconGold)),
                              SizedBox(width: 32),
                              Text('₹ ${p.cost}L', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                              SizedBox(width: 16),
                              SizedBox(
                                width: 80,
                                child: ElevatedButton(
                                  onPressed: () {
                                    // Placeholder action: view details or release
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: Text('Player'),
                                        content: Text('${p.name} • ${p.role} • ₹${p.cost}L'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Close')),
                                        ],
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: iconGreen),
                                  child: Text('View', style: TextStyle(color: iconGold)),
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
      ),
    );
  }
}
