import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ipl_auction_game/parameters.dart';
import 'package:ipl_auction_game/screens/profile_screen.dart';
import 'package:ipl_auction_game/settings.dart';
import 'package:ipl_auction_game/about.dart';
import 'package:ipl_auction_game/notifications.dart';
import 'package:ipl_auction_game/lobby.dart';

// Homepage for the app
// Buttons : Create Lobby , Join Lobby , Settings , About , Exit
// Each button navigates to respective pages (to be implemented later)

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  String roomGate(int len) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random();
    return List.generate(len, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  @override
  Widget build(BuildContext context) {
    //
    final size = MediaQuery.of(context).size;
    final hei = size.height, wid = size.width;
    final fs = max(14.0, wid * 0.045);
    final double btnWidth = min(420.0, max(160.0, wid * 0.45));
    final double btnHeight = max(44.0, hei * 0.06);
    //
    return Scaffold(
      backgroundColor: iconGreen.withAlpha(100),
      appBar: AppBar(
        backgroundColor: iconGreen.withAlpha(100),
        title: Text(
          "IPL Auction",
          style: TextStyle(fontWeight: FontWeight.w700, color: iconGold),
        ),
        leading: Padding(
          padding: EdgeInsets.all(8.0),
          child: Image.asset('assets/Logo_no_bg.png'),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context, PageRouteBuilder(pageBuilder: (_, __, ___) => const ProfileScreen(), transitionDuration: Duration.zero, reverseTransitionDuration: Duration.zero, transitionsBuilder: (_, __, ___, child) => child)),
            icon: Icon(Icons.person, color: iconGold),
          ),
          IconButton(
            onPressed: () => Navigator.push(context, PageRouteBuilder(pageBuilder: (_, __, ___) => SettingsPage(), transitionDuration: Duration.zero, reverseTransitionDuration: Duration.zero, transitionsBuilder: (_, __, ___, child) => child)),
            icon: Icon(Icons.settings, color: iconGold),
          ),
          PopupMenuButton<String>(
            color: iconPurple.withAlpha(220),
            icon: Icon(Icons.more_vert, color: iconGold),
            onSelected: (v) {
              if (v == 'about') Navigator.push(context, PageRouteBuilder(pageBuilder: (_, __, ___) => AboutPage(), transitionDuration: Duration.zero, reverseTransitionDuration: Duration.zero, transitionsBuilder: (_, __, ___, child) => child));
            },
            itemBuilder: (_) => [PopupMenuItem(value: 'about', child: Text('About', style: TextStyle(color: iconGold)))],
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Hi, Dhamodharan 👋",
              style: TextStyle(color: iconGold, fontSize: fs + 2),
            ),
            SizedBox(height: hei * 0.05),
            _actionButton('Create Room', _createRoom, btnWidth, btnHeight, max(14.0, wid * 0.04)),
            SizedBox(height: hei * 0.03),
            _actionButton('Join Room', _showJoinDialog, btnWidth, btnHeight, max(14.0, wid * 0.04)),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(String label, VoidCallback onTap, double width, double height, double fontSize) => InkWell(
        onTap: () => onTap(),
        child: Container(
          width: width,
          height: height,
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), border: Border.all(color: iconGold, width: 1), color: iconGold.withAlpha(30)),
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: iconGold, fontSize: fontSize)),
        ),
      );

  void _createRoom() {
    final code = roomGate(5);
    _createdRooms.add(code); // Store created room
    if (!mounted) return;
    
    FocusScope.of(context).unfocus();
    
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: iconPurple.withAlpha(230),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        title: Text('Room Created', style: TextStyle(color: iconGold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Share this code to join the room:', style: TextStyle(color: iconGold.withAlpha(200))),
            SizedBox(height: 12),
            SelectableText(code, style: TextStyle(color: iconGold, fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            style: TextButton.styleFrom(foregroundColor: iconGold),
            child: Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              Navigator.of(dialogContext).pop();
              if (mounted) showSuccess(context, 'Room code copied to clipboard');
            },
            style: TextButton.styleFrom(foregroundColor: iconGold),
            child: Text('Copy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (mounted) {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => Lobby(roomCode: code, isHost: true, currentPlayerName: 'Player 1 (Host)'),
                    transitionDuration: Duration.zero,
                    reverseTransitionDuration: Duration.zero,
                    transitionsBuilder: (_, __, ___, child) => child,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: Text('Go to Lobby'),
          ),
        ],
      ),
    );
  }

  // Mock storage for created rooms (replace with Firebase in production)
  static final Set<String> _createdRooms = {};

  Future<void> _showJoinDialog() async {
    final controller = TextEditingController();
    try {
      if (!mounted) return;
      
      FocusScope.of(context).unfocus();
      
      final result = await showDialog<String?>(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: iconPurple.withAlpha(220),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          title: Text('Join Room', style: TextStyle(color: iconGold)),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Enter room code',
              hintStyle: TextStyle(color: iconGold.withAlpha(100)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            style: TextStyle(color: iconGold),
            cursorColor: iconGold,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text('Cancel'),
              style: TextButton.styleFrom(foregroundColor: iconGold),
            ),
            TextButton(
              onPressed: () {
                final code = controller.text.trim();
                if(code.length != 5) {
                  showError(context, 'Please enter a valid room code');
                  return;
                }
                Navigator.of(dialogContext).pop(code);
              },
              child: Text('Join'),
              style: TextButton.styleFrom(foregroundColor: Colors.green),
            ),
          ],
        ),
      );

      if (result != null && mounted) {
        if (result.isNotEmpty) {
          // Validate room exists
          if (!_createdRooms.contains(result)) {
            showError(context, 'Incorrect room code');
            return;
          }
          showInfo(context, 'Joining room: $result');
          await Future.delayed(Duration(milliseconds: 800));
          if (mounted) {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => Lobby(roomCode: result, isHost: false, currentPlayerName: 'Player ${Random().nextInt(99) + 1}'),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
                transitionsBuilder: (_, __, ___, child) => child,
              ),
            );
          }
        } else {
          showError(context, 'Please enter a valid room code');
        }
      }
    } finally {
      controller.dispose();
    }
  }
}
