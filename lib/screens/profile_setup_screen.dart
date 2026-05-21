import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ipl_auction_game/providers/session_controller.dart';
import 'package:ipl_auction_game/screens/home_screen.dart';
import 'package:ipl_auction_game/widgets/glass_card.dart';
import 'package:ipl_auction_game/widgets/neon_button.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username is required')),
      );
      return;
    }

    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Valid email is required')),
      );
      return;
    }

    await ref.read(sessionControllerProvider.notifier).saveProfile(
          username: _nameController.text.trim(),
          email: email,
        );

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    final loading = session.loading;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_emailController.text.isEmpty && (session.accountEmail ?? '').isNotEmpty) {
        _emailController.text = session.accountEmail!;
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Complete Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GlassCard(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Email: ${session.accountEmail ?? 'Not provided'}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  maxLength: 18,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email ID'),
                ),
                const SizedBox(height: 16),
                NeonButton(
                  label: loading ? 'Saving...' : 'Enter Lobby',
                  onTap: loading ? null : _save,
                  icon: Icons.verified_user,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
