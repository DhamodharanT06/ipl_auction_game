import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../parameters.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';
import '../screens/profile_screen.dart';
import 'settings_page.dart';
import 'about_page.dart';
import 'lobby_page.dart';
import '../notifications.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final hei = size.height, wid = size.width;
    final fs = max(14.0, wid * 0.045);
    final double btnWidth = min(420.0, max(160.0, wid * 0.45));
    final double btnHeight = max(44.0, hei * 0.06);
    
    final authProvider = Provider.of<AuthProvider>(context);
    final username = authProvider.userProfile?.username ?? 'Player';

    return Scaffold(
      backgroundColor: iconGreen.withAlpha(100),
      appBar: AppBar(
        backgroundColor: iconGreen.withAlpha(100),
        elevation: 0,
        title: Text(
          "IPL Auction",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: iconGold,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/Logo_no_bg.png'),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => const ProfileScreen(),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
                transitionsBuilder: (_, __, ___, child) => child,
              ),
            ),
            icon: Icon(Icons.person, color: iconGold),
          ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => const SettingsPage(),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
                transitionsBuilder: (_, __, ___, child) => child,
              ),
            ),
            icon: Icon(Icons.settings, color: iconGold),
          ),
          PopupMenuButton<String>(
            color: iconPurple.withAlpha(220),
            icon: Icon(Icons.more_vert, color: iconGold),
            onSelected: (v) {
              if (v == 'about') {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => const AboutPage(),
                    transitionDuration: Duration.zero,
                    reverseTransitionDuration: Duration.zero,
                    transitionsBuilder: (_, __, ___, child) => child,
                  ),
                );
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'about',
                child: Text('About', style: TextStyle(color: iconGold)),
              ),
            ],
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Hi, $username 👋",
              style: TextStyle(color: iconGold, fontSize: fs + 2),
            ),
            SizedBox(height: hei * 0.05),
            _actionButton('Create Room', () => _createRoom(authProvider), btnWidth, btnHeight, max(14.0, wid * 0.04)),
            SizedBox(height: hei * 0.03),
            _actionButton('Join Room', _showJoinDialog, btnWidth, btnHeight, max(14.0, wid * 0.04)),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(String label, VoidCallback onTap, double width, double height, double fontSize) => InkWell(
        onTap: onTap,
        child: Container(
          width: width,
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: iconGold, width: 1),
            color: iconGold.withAlpha(30),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: iconGold, fontSize: fontSize),
          ),
        ),
      );

  Future<void> _createRoom(AuthProvider authProvider) async {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    
    FocusScope.of(context).unfocus();
    
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Center(
        child: CircularProgressIndicator(color: iconGold),
      ),
    );

    final success = await gameProvider.createRoom(
      authProvider.userProfile?.id ?? '',
      authProvider.userProfile?.username ?? 'Host',
    );

    if (!mounted) return;
    Navigator.of(context).pop(); // Close loading dialog

    if (success && gameProvider.currentRoom != null) {
      showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: iconPurple.withAlpha(230),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text('Room Created', style: TextStyle(color: iconGold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Share this code to join the room:',
                style: TextStyle(color: iconGold.withAlpha(200)),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: iconGold.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: iconGold, width: 1),
                ),
                child: SelectableText(
                  gameProvider.currentRoom!.roomCode,
                  style: TextStyle(
                    color: iconGold,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Close', style: TextStyle(color: iconGold)),
            ),
            TextButton(
              onPressed: () {
                Clipboard.setData(
                  ClipboardData(text: gameProvider.currentRoom!.roomCode),
                );
                Navigator.of(dialogContext).pop();
                if (mounted) {
                  showSuccess(context, 'Room code copied to clipboard');
                }
              },
              child: Text('Copy', style: TextStyle(color: iconGold)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (mounted) {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const LobbyPage(),
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                      transitionsBuilder: (_, __, ___, child) => child,
                    ),
                  );
                }
              },
              child: Text('Go to Lobby', style: TextStyle(color: Colors.green)),
            ),
          ],
        ),
      );
    } else {
      showError(context, gameProvider.error ?? 'Failed to create room');
    }
  }

  Future<void> _showJoinDialog() async {
    final controller = TextEditingController();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    
    try {
      if (!mounted) return;
      
      FocusScope.of(context).unfocus();
      
      final result = await showDialog<String?>(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: iconPurple.withAlpha(220),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text('Join Room', style: TextStyle(color: iconGold)),
          content: TextField(
            controller: controller,
            textCapitalization: TextCapitalization.characters,
            maxLength: 6,
            decoration: InputDecoration(
              hintText: 'Enter room code',
              hintStyle: TextStyle(color: iconGold.withAlpha(100)),
              counterText: '',
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: iconGold.withAlpha(100)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: iconGold, width: 2),
              ),
            ),
            style: TextStyle(
              color: iconGold,
              fontSize: 18,
              letterSpacing: 2,
            ),
            cursorColor: iconGold,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Cancel', style: TextStyle(color: iconGold)),
            ),
            TextButton(
              onPressed: () {
                final code = controller.text.trim().toUpperCase();
                if (code.length != 6) {
                  showError(context, 'Please enter a valid 6-character room code');
                  return;
                }
                Navigator.of(dialogContext).pop(code);
              },
              child: Text('Join', style: TextStyle(color: Colors.green)),
            ),
          ],
        ),
      );

      if (result != null && mounted) {
        if (result.isNotEmpty) {
          // Show loading
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => Center(
              child: CircularProgressIndicator(color: iconGold),
            ),
          );

          final success = await gameProvider.joinRoom(
            result,
            authProvider.userProfile?.id ?? '',
            authProvider.userProfile?.username ?? 'Player',
          );

          if (!mounted) return;
          Navigator.of(context).pop(); // Close loading dialog

          if (success) {
            showSuccess(context, 'Joined room successfully');
            await Future.delayed(const Duration(milliseconds: 500));
            if (mounted) {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => const LobbyPage(),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                  transitionsBuilder: (_, __, ___, child) => child,
                ),
              );
            }
          } else {
            showError(context, gameProvider.error ?? 'Failed to join room');
          }
        }
      }
    } finally {
      controller.dispose();
    }
  }
}
