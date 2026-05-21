import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ipl_auction_game/providers/app_providers.dart';
import 'package:ipl_auction_game/providers/players_provider.dart';
import 'package:ipl_auction_game/providers/session_controller.dart';
import 'package:ipl_auction_game/screens/home_screen.dart';
import 'package:ipl_auction_game/screens/profile_setup_screen.dart';
import 'package:ipl_auction_game/screens/signin_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await ref.read(cacheServiceProvider).init();
    await ref.read(sessionControllerProvider.notifier).bootstrap();
    ref.read(playersProvider.future);

    if (!mounted) {
      return;
    }

    final session = ref.read(sessionControllerProvider);
    final next = session.uid == null
        ? const SignInScreen()
        : (session.user == null ? const ProfileSetupScreen() : const HomeScreen());
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => next,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [Color(0xFF1E293B), Color(0xFF090B10)],
            radius: 1.2,
            center: Alignment.topCenter,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading auction arena...'),
            ],
          ),
        ),
      ),
    );
  }
}
