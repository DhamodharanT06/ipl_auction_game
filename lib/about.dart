import 'package:flutter/material.dart';
import 'package:ipl_auction_game/parameters.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('About', style: TextStyle(color: iconGold)),
        backgroundColor: iconGreen.withAlpha(100),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'IPL Auction Game\nVersion 1.0.0\n\nThis is a placeholder About page.',
          style: TextStyle(color: iconGold),
        ),
      ),
    );
  }
}
