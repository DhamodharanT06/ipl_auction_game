import 'package:flutter/material.dart';
import 'package:ipl_auction_game/parameters.dart';
import 'package:ipl_auction_game/models.dart';
import 'package:ipl_auction_game/my_buys.dart';

class PlayersListPage extends StatefulWidget {
  final List<Player> allPlayers;
  final List<GameTeam> teams;
  final VoidCallback? onContinue;
  final bool isHost;
  final String currentPlayerName;

  const PlayersListPage({
    super.key,
    required this.allPlayers,
    required this.teams,
    this.onContinue,
    this.isHost = false,
    required this.currentPlayerName,
  });

  @override
  State<PlayersListPage> createState() => _PlayersListPageState();
}

class _PlayersListPageState extends State<PlayersListPage> {
  String filterStatus = 'All'; // All, Sold, Unsold
  String filterRole = 'All'; // All, WK-Batsman, Batsman, Bowler, All-rounder

  List<Player> get filteredPlayers {
    return widget.allPlayers.where((player) {
      if (filterStatus == 'Sold' && !player.isSold) return false;
      if (filterStatus == 'Unsold' && player.isSold) return false;
      if (filterRole != 'All' && !player.role.toLowerCase().contains(filterRole.toLowerCase())) return false;
      return true;
    }).toList();
  }

  int get soldCount => widget.allPlayers.where((p) => p.isSold).length;
  int get unsoldCount => widget.allPlayers.where((p) => !p.isSold).length;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => widget.onContinue == null,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: iconPurple.withAlpha(250),
          title: Text('📋 Players List', style: TextStyle(color: iconGold, fontWeight: FontWeight.bold)),
          leading: widget.onContinue == null
              ? IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.arrow_back, color: iconGold))
              : null,
          automaticallyImplyLeading: widget.onContinue == null,
          actions: [
            IconButton(
              tooltip: 'My Bought Players',
              onPressed: () {
                try {
                  final myTeam = widget.teams.firstWhere((t) => t.playerName == widget.currentPlayerName);
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => MyBuysPage(myPlayers: myTeam.players, teamName: myTeam.teamName),
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                      transitionsBuilder: (_, __, ___, child) => child,
                    ),
                  );
                } catch (_) {}
              },
              icon: Icon(Icons.shopping_bag, color: iconGold),
            ),
          ],
        ),
        body: Column(
          children: [
            // Stats bar
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [iconGold.withAlpha(100), iconGold.withAlpha(50)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatCard('Total', '${widget.allPlayers.length}', Colors.blue),
                  _buildStatCard('Sold', '$soldCount', Colors.green),
                  _buildStatCard('Unsold', '$unsoldCount', Colors.orange),
                ],
              ),
            ),

            // Filters
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: iconPurple.withAlpha(100),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: filterStatus,
                      decoration: InputDecoration(labelText: 'Status', labelStyle: TextStyle(color: iconGold), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                      dropdownColor: iconPurple,
                      style: TextStyle(color: iconGold),
                      items: ['All', 'Sold', 'Unsold'].map((s) => DropdownMenuItem(value: s, child: Text(s, style: TextStyle(color: iconGold)))).toList(),
                      onChanged: (v) => setState(() => filterStatus = v ?? 'All'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: filterRole,
                      decoration: InputDecoration(labelText: 'Role', labelStyle: TextStyle(color: iconGold), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                      dropdownColor: iconPurple,
                      style: TextStyle(color: iconGold),
                      items: ['All', 'WK-Batsman', 'Batsman', 'Bowler', 'All-rounder'].map((r) => DropdownMenuItem(value: r, child: Text(r, style: TextStyle(color: iconGold, fontSize: 13)))).toList(),
                      onChanged: (v) => setState(() => filterRole = v ?? 'All'),
                    ),
                  ),
                ],
              ),
            ),

            // Table header
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: iconGold.withAlpha(150), border: Border(bottom: BorderSide(color: iconGold, width: 2))),
              child: Row(children: [
                Container(width: 40, child: Text('#', style: TextStyle(color: iconPurple, fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
                Expanded(flex: 3, child: Text('PLAYER NAME', style: TextStyle(color: iconPurple, fontWeight: FontWeight.bold, fontSize: 12))),
                SizedBox(width: 8),
                Container(width: 30, child: Text('ROLE', style: TextStyle(color: iconPurple, fontWeight: FontWeight.bold, fontSize: 10), textAlign: TextAlign.center)),
                SizedBox(width: 8),
                Container(width: 60, child: Text('BASE', style: TextStyle(color: iconPurple, fontWeight: FontWeight.bold, fontSize: 10), textAlign: TextAlign.center)),
                SizedBox(width: 8),
                Container(width: 30, child: Icon(Icons.flag, color: iconPurple, size: 16)),
                SizedBox(width: 8),
                Expanded(flex: 2, child: Text('STATUS', style: TextStyle(color: iconPurple, fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
              ]),
            ),

            // Players list
            Expanded(
              child: filteredPlayers.isEmpty
                  ? Center(child: Text('No players found', style: TextStyle(color: iconGold.withAlpha(150), fontSize: 16)))
                  : ListView.builder(
                      itemCount: filteredPlayers.length,
                      itemBuilder: (ctx, idx) {
                        final player = filteredPlayers[idx];
                        final globalIndex = widget.allPlayers.indexOf(player) + 1;

                        return Container(
                          margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: player.isSold ? [Colors.green.withAlpha(50), Colors.green.withAlpha(30)] : [iconPurple.withAlpha(100), iconPurple.withAlpha(50)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: player.isSold ? Colors.green : iconGold.withAlpha(100), width: 1),
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(children: [
                              Container(width: 40, height: 40, decoration: BoxDecoration(color: player.isSold ? Colors.green.withAlpha(150) : iconGold.withAlpha(150), shape: BoxShape.circle), child: Center(child: Text('$globalIndex', style: TextStyle(color: player.isSold ? Colors.white : iconPurple, fontWeight: FontWeight.bold, fontSize: 14)))),
                              SizedBox(width: 12),
                              Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(player.name, style: TextStyle(color: iconGold, fontWeight: FontWeight.bold, fontSize: 14)), if (player.isSold && player.soldToTeam != null) Text('${player.soldToTeam} • ₹${player.soldPrice}L', style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.w600))])),
                              SizedBox(width: 8),
                              Container(width: 30, child: _buildRoleIcon(player.role)),
                              SizedBox(width: 8),
                              Container(width: 60, child: Text(player.basePrice != null ? '₹${player.basePrice}L' : '-', style: TextStyle(color: iconGold), textAlign: TextAlign.center)),
                              SizedBox(width: 12),
                              Container(width: 30, child: player.isForeign ? Icon(Icons.flight_takeoff, color: Colors.blueAccent, size: 18) : Icon(Icons.home, color: Colors.greenAccent, size: 18)),
                              SizedBox(width: 8),
                              Expanded(flex: 2, child: Container(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: player.isSold ? Colors.green.withAlpha(150) : Colors.orange.withAlpha(150), borderRadius: BorderRadius.circular(12)), child: Text(player.isSold ? 'SOLD' : 'UNSOLD', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center))),
                            ]),
                          ),
                        );
                      },
                    ),
            ),

            // Continue area (host continue button or waiting message)
            if (widget.onContinue != null)
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(color: iconPurple.withAlpha(200), border: Border(top: BorderSide(color: iconGold, width: 2))),
                child: Column(children: [
                  if (widget.isHost)
                    ElevatedButton(
                      onPressed: widget.onContinue,
                      style: ElevatedButton.styleFrom(backgroundColor: iconGreen, padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.play_arrow, color: iconGold), SizedBox(width: 8), Text('Continue Auction', style: TextStyle(color: iconGold, fontWeight: FontWeight.bold, fontSize: 16))]),
                    )
                  else
                    Container(padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12), decoration: BoxDecoration(color: iconPurple.withAlpha(150), borderRadius: BorderRadius.circular(8)), child: Text('⏳ Waiting for host to continue auction...', style: TextStyle(color: iconGold.withAlpha(180), fontStyle: FontStyle.italic, fontSize: 14))),
                ]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(color: color.withAlpha(100), borderRadius: BorderRadius.circular(12), border: Border.all(color: color, width: 2)),
      child: Column(children: [Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)), SizedBox(height: 4), Text(label, style: TextStyle(color: iconGold, fontSize: 12, fontWeight: FontWeight.w600))]),
    );
  }

  Widget _buildRoleIcon(String role) {
    IconData icon;
    Color color;

    if (role.toLowerCase().contains('wk')) {
      icon = Icons.sports_handball;
      color = Colors.blue;
    } else if (role.toLowerCase().contains('bat')) {
      icon = Icons.sports_cricket;
      color = Colors.orange;
    } else if (role.toLowerCase().contains('bowl')) {
      icon = Icons.sports_baseball;
      color = Colors.red;
    } else {
      icon = Icons.stars;
      color = Colors.amber;
    }

    return Icon(icon, color: color, size: 20);
  }
}
