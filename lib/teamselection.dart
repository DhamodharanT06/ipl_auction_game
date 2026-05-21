import 'package:flutter/material.dart';
import 'package:ipl_auction_game/parameters.dart';
import 'package:ipl_auction_game/notifications.dart';
import 'package:ipl_auction_game/auction.dart';
import 'package:ipl_auction_game/models.dart';

class TeamSelection extends StatefulWidget {
  final List<GameTeam> teams;
  final String currentPlayerName;
  const TeamSelection({
    super.key,
    required this.teams,
    required this.currentPlayerName,
  });

  @override
  State<TeamSelection> createState() => _TeamSelectionState();
}

class _TeamSelectionState extends State<TeamSelection> {
  final List<Map<String, String>> iplTeams = [
    {'name': 'Mumbai Indians', 'code': 'MI'},
    {'name': 'Chennai Super Kings', 'code': 'CSK'},
    {'name': 'Royal Challengers Bangalore', 'code': 'RCB'},
    {'name': 'Kolkata Knight Riders', 'code': 'KKR'},
    {'name': 'Delhi Capitals', 'code': 'DC'},
    {'name': 'Rajasthan Royals', 'code': 'RR'},
    {'name': 'Punjab Kings', 'code': 'PBKS'},
    {'name': 'Sunrisers Hyderabad', 'code': 'SRH'},
    {'name': 'Lucknow Super Giants', 'code': 'LSG'},
    {'name': 'Gujarat Titans', 'code': 'GT'},
  ];

  String? selectedTeam;
  int currentPlayerIndex = 0;

  bool get allTeamsSelected => widget.teams.every((t) => t.teamName.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final hei = size.height, wid = size.width;

    return WillPopScope(
      onWillPop: () async {
        // Show confirmation dialog before going back
        final shouldPop = await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                backgroundColor: iconPurple.withAlpha(230),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                title: Text(
                  'Leave Team Selection?',
                  style: TextStyle(color: iconGold),
                ),
                content: Text(
                  'Are you sure you want to go back? Team selection progress will be lost.',
                  style: TextStyle(color: iconGold.withAlpha(200)),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text('Stay', style: TextStyle(color: iconGold)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text('Leave', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
        );
        return shouldPop ?? false;
      },
      child: Scaffold(
        backgroundColor: iconGreen.withAlpha(100),
        appBar: AppBar(
          backgroundColor: iconGreen.withAlpha(100),
          title: Text(
            'Select Your Team',
            style: TextStyle(color: iconGold, fontWeight: FontWeight.bold),
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(12.0),
            child: Column(
              children: [
                Text(
                  currentPlayerIndex < widget.teams.length
                      ? '${widget.teams[currentPlayerIndex].playerName} - Choose Your IPL Team'
                      : 'All Teams Selected',
                  style: TextStyle(
                    color: iconGold,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: hei * 0.03),
                GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: wid > 600 ? 3 : 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: iplTeams.length,
                  itemBuilder: (ctx, idx) {
                    final team = iplTeams[idx];
                    final isSelected = selectedTeam == team['code'];
                    final isAlreadyTaken = widget.teams.any(
                      (t) => t.teamName == team['code'],
                    );
                    return GestureDetector(
                      onTap:
                          isAlreadyTaken
                              ? null
                              : () {
                                setState(() => selectedTeam = team['code']);
                                // Haptic feedback simulation with scale animation
                              },
                      child: AnimatedScale(
                        scale: isSelected ? 1.05 : 1.0,
                        duration: Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  isSelected
                                      ? iconGold
                                      : isAlreadyTaken
                                      ? Colors.red
                                      : Colors.grey,
                              width: isSelected ? 3 : 1,
                            ),
                            color:
                                isSelected
                                    ? iconGold.withAlpha(80)
                                    : isAlreadyTaken
                                    ? Colors.grey.withAlpha(100)
                                    : iconPurple.withAlpha(150),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                team['code']!,
                                style: TextStyle(
                                  color: iconGold,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                team['name']!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: iconGold.withAlpha(200),
                                  fontSize: 12,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (isSelected)
                                Padding(
                                  padding: EdgeInsets.only(top: 8),
                                  child: Icon(
                                    Icons.check_circle,
                                    color: iconGold,
                                  ),
                                )
                              else if (isAlreadyTaken)
                                Padding(
                                  padding: EdgeInsets.only(top: 8),
                                  child: Icon(
                                    Icons.block,
                                    color: Colors.red,
                                    size: 20,
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
                ElevatedButton(
                  onPressed:
                      selectedTeam != null
                          ? () {
                            // Assign team to current player
                            widget.teams[currentPlayerIndex].teamName =
                                selectedTeam!;

                            if (currentPlayerIndex < widget.teams.length - 1) {
                              // Show celebration animation
                              showSuccess(
                                context,
                                '🎉 ${selectedTeam!} selected! Next player\'s turn',
                              );

                              // Move to next player with delay for better UX
                              Future.delayed(Duration(milliseconds: 800), () {
                                if (mounted) {
                                  setState(() {
                                    currentPlayerIndex++;
                                    selectedTeam = null;
                                  });
                                }
                              });
                            } else {
                              // All teams selected, start auction
                              showSuccess(
                                context,
                                'All teams selected! Starting auction...',
                              );
                              Future.delayed(Duration(milliseconds: 800), () {
                                if (mounted) {
                                  // Create AuctionState and proceed to auction
                                  final playersToAuction = [
                                    // WK-Batsmen (must have at least enough for all teams)
                                    Player(
                                      name: 'MS Dhoni',
                                      role: 'WK-Batsman',
                                      avgScore: 38,
                                      isForeign: false,
                                      previousTeam: 'CSK',
                                    ),
                                    Player(
                                      name: 'Rishabh Pant',
                                      role: 'WK-Batsman',
                                      avgScore: 40,
                                      isForeign: false,
                                      previousTeam: 'LSG',
                                    ),
                                    Player(
                                      name: 'KL Rahul',
                                      role: 'WK-Batsman',
                                      avgScore: 42,
                                      isForeign: false,
                                      previousTeam: 'DC',
                                    ),
                                    Player(
                                      name: 'Ishan Kishan',
                                      role: 'WK-Batsman',
                                      avgScore: 35,
                                      isForeign: false,
                                      previousTeam: 'MI',
                                    ),
                                    Player(
                                      name: 'Quinton de Kock',
                                      role: 'WK-Batsman',
                                      avgScore: 40,
                                      isForeign: true,
                                      previousTeam: 'LSG',
                                    ),
                                    Player(
                                      name: 'Jos Buttler',
                                      role: 'WK-Batsman',
                                      avgScore: 45,
                                      isForeign: true,
                                      previousTeam: 'RR',
                                    ),
                                    Player(
                                      name: 'Sanju Samson',
                                      role: 'WK-Batsman',
                                      avgScore: 38,
                                      isForeign: false,
                                      previousTeam: 'RR',
                                    ),
                                    Player(
                                      name: 'Nicholas Pooran',
                                      role: 'WK-Batsman',
                                      avgScore: 36,
                                      isForeign: true,
                                      previousTeam: 'SRH',
                                    ),
                                    // Batsmen
                                    Player(
                                      name: 'Virat Kohli',
                                      role: 'Batsman',
                                      avgScore: 45,
                                      isForeign: false,
                                      previousTeam: 'RCB',
                                    ),
                                    Player(
                                      name: 'Rohit Sharma',
                                      role: 'Batsman',
                                      avgScore: 42,
                                      isForeign: false,
                                      previousTeam: 'MI',
                                    ),
                                    Player(
                                      name: 'AB de Villiers',
                                      role: 'Batsman',
                                      avgScore: 48,
                                      isForeign: true,
                                      previousTeam: 'RCB',
                                    ),
                                    Player(
                                      name: 'Suryakumar Yadav',
                                      role: 'Batsman',
                                      avgScore: 48,
                                      isForeign: false,
                                      previousTeam: 'MI',
                                    ),
                                    Player(
                                      name: 'Shreyas Iyer',
                                      role: 'Batsman',
                                      avgScore: 40,
                                      isForeign: false,
                                      previousTeam: 'PBKS',
                                    ),
                                    // Bowlers
                                    Player(
                                      name: 'Jasprit Bumrah',
                                      role: 'Bowler',
                                      avgScore: 15,
                                      isForeign: false,
                                      previousTeam: 'MI',
                                    ),
                                    Player(
                                      name: 'Rashid Khan',
                                      role: 'Bowler',
                                      avgScore: 18,
                                      isForeign: true,
                                      previousTeam: 'GT',
                                    ),
                                    Player(
                                      name: 'Bhuvaneswar Kumar',
                                      role: 'Bowler',
                                      avgScore: 42,
                                      isForeign: false,
                                      previousTeam: 'RCB',
                                    ),
                                    // All-rounders
                                    Player(
                                      name: 'Hardik Pandya',
                                      role: 'All-rounder',
                                      avgScore: 40,
                                      isForeign: false,
                                      previousTeam: 'MI',
                                    ),
                                    Player(
                                      name: 'Ravindra Jadeja',
                                      role: 'All-rounder',
                                      avgScore: 45,
                                      isForeign: false,
                                      previousTeam: 'CSK',
                                    ),
                                    Player(
                                      name: 'Kieron Pollard',
                                      role: 'All-rounder',
                                      avgScore: 40,
                                      isForeign: true,
                                      previousTeam: 'MI',
                                    ),
                                    Player(
                                      name: 'Michael Marsh',
                                      role: 'All-rounder',
                                      avgScore: 35,
                                      isForeign: true,
                                      previousTeam: 'LSG',
                                    ),
                                  ];

                                  final auctionState = AuctionState(
                                    teams: widget.teams,
                                    playersToAuction: playersToAuction,
                                  );

                                  Navigator.pushReplacement(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder:
                                          (_, __, ___) => AuctionPage(
                                            auctionState: auctionState,
                                            currentPlayerName:
                                                widget.currentPlayerName,
                                          ),
                                      transitionDuration: Duration.zero,
                                      reverseTransitionDuration: Duration.zero,
                                      transitionsBuilder:
                                          (_, __, ___, child) => child,
                                    ),
                                  );
                                }
                              });
                            }
                          }
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        selectedTeam != null ? iconGold : Colors.grey,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    currentPlayerIndex < widget.teams.length - 1
                        ? 'Confirm & Next'
                        : 'Start Auction',
                    style: TextStyle(
                      color: iconPurple,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Removed forward declaration - now properly imported
