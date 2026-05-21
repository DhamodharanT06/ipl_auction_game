import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ipl_auction_game/parameters.dart';
import 'package:ipl_auction_game/providers/session_controller.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _usernameController;
  late int _selectedAvatarIndex;
  late bool _soundEnabled;
  late bool _darkModeEnabled;
  bool _isEditingName = false;

  static const List<String> _avatarUrls = [
    'https://api.dicebear.com/7.x/avataaars/png?seed=avatar1&size=256',
    'https://api.dicebear.com/7.x/avataaars/png?seed=avatar2&size=256',
    'https://api.dicebear.com/7.x/avataaars/png?seed=avatar3&size=256',
    'https://api.dicebear.com/7.x/avataaars/png?seed=avatar4&size=256',
    'https://api.dicebear.com/7.x/avataaars/png?seed=avatar5&size=256',
    'https://api.dicebear.com/7.x/avataaars/png?seed=avatar6&size=256',
    'https://api.dicebear.com/7.x/avataaars/png?seed=avatar7&size=256',
    'https://api.dicebear.com/7.x/avataaars/png?seed=avatar8&size=256',
    'https://api.dicebear.com/7.x/avataaars/png?seed=avatar9&size=256',
    'https://api.dicebear.com/7.x/avataaars/png?seed=avatar10&size=256',
  ];

  @override
  void initState() {
    super.initState();
    final user = ref.read(sessionControllerProvider).user;
    _usernameController = TextEditingController(text: user?.username ?? '');
    _selectedAvatarIndex = _parseAvatarIndex(user?.avatarUrl);
    _soundEnabled = user?.soundEnabled ?? true;
    _darkModeEnabled = user?.darkModeEnabled ?? false;
  }

  int _parseAvatarIndex(String? avatarUrl) {
    if (avatarUrl == null) return 0;
    for (var i = 0; i < _avatarUrls.length; i++) {
      if (_avatarUrls[i] == avatarUrl) return i;
    }
    return 0;
  }

  Future<void> _saveProfile({bool showSuccess = false}) async {
    final currentUser = ref.read(sessionControllerProvider).user;
    if (currentUser == null) return;

    final username = _usernameController.text.trim().isEmpty
        ? currentUser.username
        : _usernameController.text.trim();

    final success = await ref.read(sessionControllerProvider.notifier).saveProfile(
          username: username,
          email: currentUser.email,
          avatarUrl: _avatarUrls[_selectedAvatarIndex],
          soundEnabled: _soundEnabled,
          darkModeEnabled: _darkModeEnabled,
        );

    if (!mounted) return;

    if (success) {
      if (showSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile')),
      );
    }
  }

  Future<void> _pickAvatar() async {
    final selectedIndex = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 14),
                Text('Choose Avatar', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('Pick a profile icon that fits your style', style: theme.textTheme.bodySmall),
                const SizedBox(height: 16),
                Flexible(
                  child: GridView.builder(
                    shrinkWrap: true,
                    itemCount: _avatarUrls.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.02,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                    ),
                    itemBuilder: (context, index) {
                      final selected = index == _selectedAvatarIndex;
                      return InkWell(
                        borderRadius: BorderRadius.circular(22),
                        onTap: () => Navigator.of(context).pop(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            color: theme.colorScheme.surfaceContainerHighest.withOpacity(selected ? 0.9 : 0.65),
                            border: Border.all(
                              color: selected ? iconGold : theme.colorScheme.outlineVariant.withOpacity(0.7),
                              width: selected ? 2 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: iconGreen.withOpacity(0.16),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _AvatarImage(url: _avatarUrls[index], size: 84),
                              const SizedBox(height: 10),
                              Text('Avatar ${index + 1}', style: theme.textTheme.labelLarge),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || selectedIndex == null) return;
    setState(() => _selectedAvatarIndex = selectedIndex);
    await _saveProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    final user = session.user;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('No user data available')),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          TextButton.icon(
            onPressed: () async {
              if (_isEditingName) {
                await _saveProfile(showSuccess: true);
              }
              if (!mounted) return;
              setState(() => _isEditingName = !_isEditingName);
            },
            icon: Icon(_isEditingName ? Icons.check_circle_outline : Icons.edit_outlined),
            label: Text(_isEditingName ? 'Save' : 'Edit'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              iconGreen.withOpacity(0.35),
              Theme.of(context).scaffoldBackgroundColor,
              iconPurple.withOpacity(0.22),
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 96, 16, 24),
          children: [
            _Panel(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.surface.withOpacity(0.88),
                  iconPurple.withOpacity(0.18),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: iconGold.withOpacity(0.25),
                              blurRadius: 24,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: _AvatarImage(url: _avatarUrls[_selectedAvatarIndex], size: 108),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Material(
                          color: iconGold,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _pickAvatar,
                            child: const Padding(
                              padding: EdgeInsets.all(10),
                              child: Icon(Icons.camera_alt_outlined, size: 18, color: Color(0xFF10231A)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PLAYER PROFILE',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: iconGold,
                            letterSpacing: 1.8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_isEditingName)
                          TextField(
                            controller: _usernameController,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) async {
                              await _saveProfile(showSuccess: true);
                              if (mounted) setState(() => _isEditingName = false);
                            },
                            decoration: const InputDecoration(
                              hintText: 'Enter username',
                            ),
                          )
                        else
                          Text(
                            user.username,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            SingleChildScrollView(scrollDirection: Axis.horizontal, child: _InfoPill(icon: Icons.mail_outline, text: user.email)),
                            _InfoPill(icon: Icons.emoji_events_outlined, text: '${user.matchesWon} wins'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Stats', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 12,
                    children: [
                      _StatCard(icon: Icons.sports_esports_outlined, label: 'Matches Played', value: user.matchesPlayed.toString()),
                      _StatCard(icon: Icons.emoji_events_outlined, label: '1st Place', value: user.matchesWon.toString()),
                      _StatCard(icon: Icons.stars_outlined, label: 'Total Coins', value: user.totalCoins.toString()),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Settings', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    activeColor: iconGold,
                    title: const Text('Sound Effects'),
                    subtitle: const Text('Play sounds during gameplay'),
                    value: _soundEnabled,
                    onChanged: (value) async {
                      setState(() => _soundEnabled = value);
                      await _saveProfile();
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    activeColor: iconGold,
                    title: const Text('Dark Mode'),
                    subtitle: const Text('Use the premium dark theme'),
                    value: _darkModeEnabled,
                    onChanged: (value) async {
                      setState(() => _darkModeEnabled = value);
                      await _saveProfile();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () async {
                await _saveProfile(showSuccess: true);
                if (mounted) setState(() => _isEditingName = false);
              },
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save Profile'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarImage extends StatelessWidget {
  const _AvatarImage({required this.url, required this.size});

  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (context, _) => Container(
          width: size,
          height: size,
          color: surface,
          alignment: Alignment.center,
          child: const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (context, _, __) => Container(
          width: size,
          height: size,
          color: surface,
          alignment: Alignment.center,
          child: Icon(Icons.person, size: 34, color: Theme.of(context).colorScheme.onSurface),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.gradient});

  final Widget child;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.34)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.18),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(text, style: theme.textTheme.labelLarge, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 140),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              iconGreen.withOpacity(0.16),
              iconPurple.withOpacity(0.16),
            ],
          ),
          border: Border.all(color: iconGold.withOpacity(0.22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconGold),
            const SizedBox(height: 14),
            Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
