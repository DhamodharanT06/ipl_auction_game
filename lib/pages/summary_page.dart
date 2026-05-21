import 'package:flutter/material.dart';
import '../parameters.dart';
import '../models/game_models.dart';
import 'home_page.dart';

class SummaryPage extends StatefulWidget {
  final List<RoomPlayer> teams;

  const SummaryPage({super.key, required this.teams});

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Sort teams by total spent (winner spent most/wisely)
    final sortedTeams = List<RoomPlayer>.from(widget.teams)
      ..sort((a, b) => _calculateSpent(b).compareTo(_calculateSpent(a)));

    final winner = sortedTeams.isNotEmpty ? sortedTeams.first : null;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [iconGold.withAlpha(150), iconPurple.withAlpha(200)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  children: [
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Column(
                          children: [
                            const Text(
                              '🏆',
                              style: TextStyle(fontSize: 60),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'AUCTION COMPLETE',
                              style: TextStyle(
                                color: iconGold,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Winner Section
              if (winner != null)
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [iconGold.withAlpha(100), iconGold.withAlpha(30)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: iconGold, width: 2),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.emoji_events, color: iconGold, size: 28),
                            const SizedBox(width: 8),
                            Text(
                              'TOP SPENDER',
                              style: TextStyle(
                                color: iconGold,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          winner.username,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          winner.teamName.isEmpty ? 'Unknown Team' : winner.teamName,
                          style: TextStyle(
                            color: iconGold.withAlpha(180),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildWinnerStat('Spent', '₹${_calculateSpent(winner)}L'),
                            _buildWinnerStat('Players', '${winner.playersOwned.length}'),
                            _buildWinnerStat('Remaining', '₹${winner.budget}L'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              // Leaderboard Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.leaderboard, color: iconGold, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'FINAL STANDINGS',
                      style: TextStyle(
                        color: iconGold,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),

              // Leaderboard List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: sortedTeams.length,
                  itemBuilder: (context, index) {
                    final team = sortedTeams[index];
                    final spent = _calculateSpent(team);
                    final isWinner = index == 0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isWinner
                              ? [iconGold.withAlpha(80), iconGold.withAlpha(30)]
                              : [iconPurple.withAlpha(100), iconPurple.withAlpha(50)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isWinner ? iconGold : iconGold.withAlpha(30),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Rank
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _getRankColor(index),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: index < 3 ? Colors.black : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
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
                                      Icon(Icons.star, color: iconGold, size: 16),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        team.username,
                                        style: TextStyle(
                                          color: isWinner ? iconGold : Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  team.teamName.isEmpty ? 'Unknown Team' : team.teamName,
                                  style: TextStyle(
                                    color: iconGold.withAlpha(150),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Stats
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${spent}L',
                                style: const TextStyle(
                                  color: Colors.greenAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '${team.playersOwned.length} players',
                                style: TextStyle(
                                  color: iconGold.withAlpha(150),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // New Game Button
              Padding(
                padding: const EdgeInsets.all(16),
                child: InkWell(
                  onTap: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => const HomePage(),
                        transitionDuration: Duration.zero,
                        reverseTransitionDuration: Duration.zero,
                        transitionsBuilder: (_, __, ___, child) => child,
                      ),
                      (route) => false,
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [iconPurple, iconPurple.withAlpha(200)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: iconGold),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.home, color: iconGold),
                        const SizedBox(width: 8),
                        Text(
                          'BACK TO HOME',
                          style: TextStyle(
                            color: iconGold,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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

  Widget _buildWinnerStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: iconGold.withAlpha(180),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 0:
        return iconGold;
      case 1:
        return Colors.grey.shade400;
      case 2:
        return Colors.brown.shade400;
      default:
        return Colors.grey.withAlpha(100);
    }
  }
}
