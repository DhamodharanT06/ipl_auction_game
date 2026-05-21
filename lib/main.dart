import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ipl_auction_game/core/theme/app_theme.dart';
import 'package:ipl_auction_game/providers/session_controller.dart';
import 'package:ipl_auction_game/screens/splash_screen.dart';

// Main entry point for IPL Auction Game - Multiplayer Edition

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ProviderScope(child: IPLAuctionApp()));
}

class IPLAuctionApp extends ConsumerWidget {
  const IPLAuctionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkModeEnabled =
        ref.watch(sessionControllerProvider.select((state) => state.user?.darkModeEnabled ?? false));

    return MaterialApp(
      title: 'IPL Auction Game',
      debugShowCheckedModeBanner: false,
      themeMode: darkModeEnabled ? ThemeMode.dark : ThemeMode.light,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const SplashScreen(),
    );
  }
}
