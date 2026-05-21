import 'package:flutter/material.dart';
import '../parameters.dart';

class TeamSelectionPage extends StatefulWidget {
  final List<String> takenTeams;
  final Function(String) onTeamSelected;

  const TeamSelectionPage({
    super.key,
    required this.takenTeams,
    required this.onTeamSelected,
  });

  @override
  State<TeamSelectionPage> createState() => _TeamSelectionPageState();
}

class _TeamSelectionPageState extends State<TeamSelectionPage> {
  String? _selectedTeam;

  // IPL Teams Data
  final List<Map<String, dynamic>> _iplTeams = [
    {
      'name': 'Mumbai Indians',
      'shortName': 'MI',
      'color': Color(0xFF004BA0),
      'secondaryColor': Color(0xFFD1AB3E),
      'logo': '🔵',
    },
    {
      'name': 'Chennai Super Kings',
      'shortName': 'CSK',
      'color': Color(0xFFFDB913),
      'secondaryColor': Color(0xFF0081E9),
      'logo': '🦁',
    },
    {
      'name': 'Royal Challengers Bangalore',
      'shortName': 'RCB',
      'color': Color(0xFFEC1C24),
      'secondaryColor': Color(0xFF000000),
      'logo': '🔴',
    },
    {
      'name': 'Kolkata Knight Riders',
      'shortName': 'KKR',
      'color': Color(0xFF3A225D),
      'secondaryColor': Color(0xFFB3A123),
      'logo': '💜',
    },
    {
      'name': 'Delhi Capitals',
      'shortName': 'DC',
      'color': Color(0xFF0078BC),
      'secondaryColor': Color(0xFFEF1B23),
      'logo': '🔷',
    },
    {
      'name': 'Rajasthan Royals',
      'shortName': 'RR',
      'color': Color(0xFFE73895),
      'secondaryColor': Color(0xFF254AA5),
      'logo': '👑',
    },
    {
      'name': 'Punjab Kings',
      'shortName': 'PBKS',
      'color': Color(0xFFED1B24),
      'secondaryColor': Color(0xFFA7A9AC),
      'logo': '🦁',
    },
    {
      'name': 'Sunrisers Hyderabad',
      'shortName': 'SRH',
      'color': Color(0xFFFF822A),
      'secondaryColor': Color(0xFF000000),
      'logo': '🌅',
    },
    {
      'name': 'Lucknow Super Giants',
      'shortName': 'LSG',
      'color': Color(0xFF0057E2),
      'secondaryColor': Color(0xFFA72056),
      'logo': '🐯',
    },
    {
      'name': 'Gujarat Titans',
      'shortName': 'GT',
      'color': Color(0xFF1C1C1C),
      'secondaryColor': Color(0xFFB2965A),
      'logo': '🛡️',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [iconPurple.withAlpha(200), iconPurple.withAlpha(150)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'SELECT YOUR FRANCHISE',
                    style: TextStyle(
                      color: iconGold,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose a team to represent in the auction',
                    style: TextStyle(
                      color: iconGold.withAlpha(180),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Teams Grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.1,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _iplTeams.length,
                itemBuilder: (context, index) {
                  final team = _iplTeams[index];
                  final isTaken = widget.takenTeams.contains(team['name']);
                  final isSelected = _selectedTeam == team['name'];

                  return InkWell(
                    onTap: isTaken ? null : () {
                      setState(() {
                        _selectedTeam = team['name'];
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isTaken
                              ? [Colors.grey.withAlpha(100), Colors.grey.withAlpha(50)]
                              : [
                                  (team['color'] as Color).withAlpha(200),
                                  (team['color'] as Color).withAlpha(100),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? iconGold
                              : isTaken
                                  ? Colors.grey.withAlpha(50)
                                  : (team['secondaryColor'] as Color).withAlpha(150),
                          width: isSelected ? 3 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: iconGold.withAlpha(50),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: Stack(
                        children: [
                          // Team Content
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  team['logo'] as String,
                                  style: TextStyle(
                                    fontSize: 36,
                                    color: isTaken ? Colors.grey : null,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  team['shortName'] as String,
                                  style: TextStyle(
                                    color: isTaken ? Colors.grey : Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  team['name'] as String,
                                  style: TextStyle(
                                    color: isTaken
                                        ? Colors.grey.withAlpha(150)
                                        : Colors.white.withAlpha(200),
                                    fontSize: 11,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          // Taken Overlay
                          if (isTaken)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(150),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withAlpha(200),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'TAKEN',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          // Selected Checkmark
                          if (isSelected)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: iconGold,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.black,
                                  size: 16,
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

            // Confirm Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: InkWell(
                onTap: _selectedTeam != null
                    ? () {
                        widget.onTeamSelected(_selectedTeam!);
                        Navigator.pop(context);
                      }
                    : null,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: _selectedTeam != null
                        ? LinearGradient(
                            colors: [iconGold, iconGold.withAlpha(200)],
                          )
                        : null,
                    color: _selectedTeam == null ? Colors.grey.withAlpha(100) : null,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedTeam != null ? iconGold : Colors.grey,
                    ),
                  ),
                  child: Text(
                    _selectedTeam != null ? 'CONFIRM $_selectedTeam' : 'SELECT A TEAM',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _selectedTeam != null ? Colors.black : Colors.grey,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
