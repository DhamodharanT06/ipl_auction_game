import 'package:flutter/material.dart';
import '../parameters.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: iconGreen.withAlpha(100),
      appBar: AppBar(
        backgroundColor: iconGreen.withAlpha(100),
        title: Text('About', style: TextStyle(color: iconGold)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: iconGold),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              
              // Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: iconGold, width: 2),
                ),
                child: Image.asset('assets/Logo_no_bg.png'),
              ),
              
              const SizedBox(height: 24),
              
              Text(
                'IPL Auction Game',
                style: TextStyle(
                  color: iconGold,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'Multiplayer Edition',
                style: TextStyle(
                  color: iconGold.withAlpha(180),
                  fontSize: 16,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'Version 1.0.0',
                style: TextStyle(
                  color: iconGold.withAlpha(150),
                  fontSize: 14,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Description Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: iconPurple.withAlpha(100),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: iconGold.withAlpha(100)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About the Game',
                      style: TextStyle(
                        color: iconGold,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Experience the thrill of an IPL auction with your friends! '
                      'Create or join rooms, bid on your favorite players, and build '
                      'your dream team.\n\n'
                      'Features:\n'
                      '• Real-time multiplayer auctions\n'
                      '• Create private rooms with friends\n'
                      '• Authentic IPL auction experience\n'
                      '• Strategic bidding and team building',
                      style: TextStyle(
                        color: iconGold.withAlpha(200),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Credits Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: iconPurple.withAlpha(100),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: iconGold.withAlpha(100)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Credits',
                      style: TextStyle(
                        color: iconGold,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Developed with ❤️ using Flutter\n'
                      'Backend powered by Appwrite',
                      style: TextStyle(
                        color: iconGold.withAlpha(200),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              Text(
                '© 2026 IPL Auction Game',
                style: TextStyle(
                  color: iconGold.withAlpha(100),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
