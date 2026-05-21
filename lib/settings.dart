import 'package:flutter/material.dart';
import 'package:ipl_auction_game/parameters.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: TextStyle(color: iconGold)),
        backgroundColor: iconGreen.withAlpha(100),
      ),
      body: Center(
        child: Text('Settings placeholder', style: TextStyle(color: iconGold)),
      ),
    );
  }
}
