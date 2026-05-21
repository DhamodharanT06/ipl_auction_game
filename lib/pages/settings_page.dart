import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../parameters.dart';
import '../providers/auth_provider.dart';
import '../notifications.dart';
import '../utils/player_seeder.dart';
import '../config/appwrite_config.dart';
import 'auth_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _soundEnabled = true;
  bool _notificationsEnabled = true;
  bool _isSeeding = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: iconGreen.withAlpha(100),
      appBar: AppBar(
        backgroundColor: iconGreen.withAlpha(100),
        title: Text('Settings', style: TextStyle(color: iconGold)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: iconGold),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Account Section
              _sectionTitle('Account'),
              const SizedBox(height: 12),
              
              _settingsTile(
                icon: Icons.person,
                title: 'Username',
                subtitle: authProvider.userProfile?.username ?? 'Player',
                onTap: () => _showEditUsernameDialog(authProvider),
              ),
              
              const SizedBox(height: 24),
              
              // Preferences Section
              _sectionTitle('Preferences'),
              const SizedBox(height: 12),
              
              _switchTile(
                icon: Icons.volume_up,
                title: 'Sound Effects',
                value: _soundEnabled,
                onChanged: (value) {
                  setState(() => _soundEnabled = value);
                  showInfo(context, 'Sound ${value ? 'enabled' : 'disabled'}');
                },
              ),
              
              _switchTile(
                icon: Icons.notifications,
                title: 'Notifications',
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() => _notificationsEnabled = value);
                  showInfo(context, 'Notifications ${value ? 'enabled' : 'disabled'}');
                },
              ),
              
              const SizedBox(height: 24),
              
              // About Section
              _sectionTitle('About'),
              const SizedBox(height: 12),
              
              _settingsTile(
                icon: Icons.info,
                title: 'App Version',
                subtitle: '1.0.0',
              ),
              
              const SizedBox(height: 24),
              
              // Admin Section
              _sectionTitle('Admin Tools'),
              const SizedBox(height: 12),
              
              _settingsTile(
                icon: Icons.sports_cricket,
                title: 'Seed Players Database',
                subtitle: _isSeeding ? 'Adding players...' : 'Add 50+ IPL players',
                onTap: _isSeeding ? null : () => _seedPlayers(authProvider),
              ),
              
              const SizedBox(height: 32),
              
              // Logout Button
              Center(
                child: InkWell(
                  onTap: () => _handleLogout(authProvider),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.red, width: 1),
                      color: Colors.red.withAlpha(30),
                    ),
                    child: const Text(
                      'Logout',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: iconGold,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconGold),
      title: Text(title, style: TextStyle(color: iconGold)),
      subtitle: subtitle != null
          ? Text(subtitle, style: TextStyle(color: iconGold.withAlpha(150)))
          : null,
      trailing: onTap != null ? Icon(Icons.chevron_right, color: iconGold) : null,
      onTap: onTap,
      tileColor: iconPurple.withAlpha(80),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: iconGold.withAlpha(100)),
      ),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconGold),
      title: Text(title, style: TextStyle(color: iconGold)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: iconGold,
      ),
      tileColor: iconPurple.withAlpha(80),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: iconGold.withAlpha(100)),
      ),
    );
  }

  Future<void> _showEditUsernameDialog(AuthProvider authProvider) async {
    final controller = TextEditingController(
      text: authProvider.userProfile?.username ?? '',
    );

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: iconPurple.withAlpha(230),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Edit Username', style: TextStyle(color: iconGold)),
        content: TextField(
          controller: controller,
          style: TextStyle(color: iconGold),
          cursorColor: iconGold,
          decoration: InputDecoration(
            hintText: 'Enter new username',
            hintStyle: TextStyle(color: iconGold.withAlpha(100)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: iconGold.withAlpha(100)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: iconGold, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: TextStyle(color: iconGold)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text('Save', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      await authProvider.updateProfile({'username': result});
      showSuccess(context, 'Username updated!');
    }
    
    controller.dispose();
  }

  Future<void> _handleLogout(AuthProvider authProvider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: iconPurple.withAlpha(230),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Logout', style: TextStyle(color: iconGold)),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: iconGold.withAlpha(200)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: TextStyle(color: iconGold)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await authProvider.logout();
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const AuthPage(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          transitionsBuilder: (_, __, ___, child) => child,
        ),
        (route) => false,
      );
    }
  }

  Future<void> _seedPlayers(AuthProvider authProvider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: iconPurple.withAlpha(230),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Seed Players', style: TextStyle(color: iconGold)),
        content: Text(
          'This will add 50+ IPL players to your database. Continue?',
          style: TextStyle(color: iconGold.withAlpha(200)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: TextStyle(color: iconGold)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Add Players', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isSeeding = true);
      
      try {
        final client = AppwriteConfig.client;
        final seeder = PlayerSeeder(client);
        await seeder.seedPlayers();
        
        if (mounted) {
          showSuccess(context, '50+ players added to database!');
        }
      } catch (e) {
        if (mounted) {
          showError(context, 'Failed to seed: $e');
        }
      } finally {
        if (mounted) {
          setState(() => _isSeeding = false);
        }
      }
    }
  }
}
