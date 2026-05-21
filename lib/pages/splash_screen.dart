import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../parameters.dart';
import '../providers/auth_provider.dart';
import 'auth_page.dart';
import 'home_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;
  late final Animation<Offset> _floatOffset;
  late final Animation<double> _floatScale;

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _floatOffset = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.05),
    ).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _floatScale = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _checkAuthAndNavigate();
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(seconds: 3));
    
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.checkAuthStatus();

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (_, __, ___) => authProvider.isAuthenticated
            ? const HomePage()
            : const AuthPage(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: iconGreen.withAlpha(100),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Logo
            AnimatedBuilder(
              animation: _floatController,
              builder: (context, child) {
                return Transform.translate(
                  offset: _floatOffset.value * 20,
                  child: Transform.scale(
                    scale: _floatScale.value,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: iconGold, width: 3),
                      ),
                      child: Hero(
                        tag: 'app_logo',
                        child: Image.asset('assets/Logo_no_bg.png'),
                      ),
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 40),
            
            // App Title
            Text(
              'IPL Auction Game',
              style: TextStyle(
                color: iconGold,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            
            const SizedBox(height: 10),
            
            Text(
              'Multiplayer Edition',
              style: TextStyle(
                color: iconGold.withAlpha(180),
                fontSize: 16,
                letterSpacing: 1,
              ),
            ),
            
            const SizedBox(height: 60),
            
            // Loading Indicator
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                color: iconGold,
                strokeWidth: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
