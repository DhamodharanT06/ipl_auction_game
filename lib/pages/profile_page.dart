import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../parameters.dart';
import '../providers/auth_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  var count = {
    "Total Played": 0,
    "1st Place": 0,
    "2nd Place": 0,
    "3rd Place": 0,
  };

  Widget stats(String title, {double? width}) {
    return SizedBox(
      width: width,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: iconGold, width: 0.5),
          borderRadius: BorderRadius.circular(5),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(title, textAlign: TextAlign.center, style: TextStyle(color: iconGold)),
            const SizedBox(height: 6.0),
            Divider(color: iconGold, thickness: 0.5),
            Text(
              count[title].toString(),
              textAlign: TextAlign.center,
              style: TextStyle(color: iconGold, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Widget details(String label, String value, IconData iconData) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: ListTile(
        leading: Icon(iconData, color: iconGold),
        title: Text(label, style: TextStyle(color: iconGold.withAlpha(180), fontSize: 12)),
        subtitle: Text(value, style: TextStyle(color: iconGold, fontSize: 16)),
        tileColor: iconPurple.withAlpha(80),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: iconGold.withAlpha(100)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final hei = size.height, wid = size.width;
    
    final authProvider = Provider.of<AuthProvider>(context);
    final profile = authProvider.userProfile;
    
    final username = profile?.username ?? 'Player';
    final userId = profile?.id ?? 'Unknown';

    // Update counts from profile if available
    if (profile != null) {
      count["Total Played"] = profile.matchesPlayed;
      count["1st Place"] = profile.matchesWon;
    }

    return Scaffold(
      backgroundColor: iconGreen.withAlpha(100),
      appBar: AppBar(
        backgroundColor: iconGreen.withAlpha(100),
        title: Text('Profile', style: TextStyle(color: iconGold)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: iconGold),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Profile Picture
                CircleAvatar(
                  radius: 60,
                  backgroundColor: iconGold,
                  child: profile?.avatarUrl != null && profile!.avatarUrl!.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            profile.avatarUrl!,
                            width: 116,
                            height: 116,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(Icons.person, color: iconPurple, size: 60),
                          ),
                        )
                      : Icon(Icons.person, color: iconPurple, size: 60),
                ),
                
                SizedBox(height: hei * 0.03),
                
                // Username
                Text(
                  username,
                  style: TextStyle(
                    color: iconGold,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // User ID
                Text(
                  'ID: ${userId.length > 8 ? userId.substring(0, 8) : userId}...',
                  style: TextStyle(
                    color: iconGold.withAlpha(150),
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
                
                SizedBox(height: hei * 0.04),
                
                // Stats Grid
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    stats("Total Played", width: max(100, wid * 0.4)),
                    stats("1st Place", width: max(100, wid * 0.4)),
                    stats("2nd Place", width: max(100, wid * 0.4)),
                    stats("3rd Place", width: max(100, wid * 0.4)),
                  ],
                ),
                
                SizedBox(height: hei * 0.04),
                
                // Details Section
                details('Username', username, Icons.person),
                details('Total Coins', '${profile?.totalCoins ?? 0}', Icons.monetization_on),
                details('Badges', '${profile?.badges.length ?? 0}', Icons.military_tech),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
