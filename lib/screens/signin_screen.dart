import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ipl_auction_game/providers/session_controller.dart';
import 'package:ipl_auction_game/screens/profile_setup_screen.dart';
import 'package:ipl_auction_game/widgets/glass_card.dart';
import 'package:ipl_auction_game/widgets/neon_button.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  final _signupConfirmPasswordController = TextEditingController();
  final _signupUsernameController = TextEditingController();

  bool _obscureLoginPassword = true;
  bool _obscureSignupPassword = true;
  bool _obscureSignupConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Generate test email on init
    _generateTestEmail();
  }

  void _generateTestEmail() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _signupEmailController.text = 'test$timestamp@example.com';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signupEmailController.dispose();
    _signupPasswordController.dispose();
    _signupConfirmPasswordController.dispose();
    _signupUsernameController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _loginEmailController.text.trim();
    final password = _loginPasswordController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      _showError('Please enter a valid email');
      return;
    }
    if (password.isEmpty) {
      _showError('Please enter your password');
      return;
    }

    print('[Login] Attempting email/password login: $email');
    
    try {
      final ok = await ref
          .read(sessionControllerProvider.notifier)
          .signInWithEmail(email: email, password: password);
      
      if (!mounted) return;
      
      if (ok) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
        );
      } else {
        _showError('Login failed. Please check your credentials.');
      }
    } catch (e) {
      print('[Login] Error: $e');
      _showError('Login failed: $e');
    }
  }

  Future<void> _handleSignUp() async {
    final username = _signupUsernameController.text.trim();
    final email = _signupEmailController.text.trim();
    final password = _signupPasswordController.text.trim();
    final confirmPassword = _signupConfirmPasswordController.text.trim();

    if (username.isEmpty || username.length < 2) {
      _showError('Username must be at least 2 characters');
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      _showError('Please enter a valid email');
      return;
    }
    if (password.isEmpty || password.length < 8) {
      _showError('Password must be at least 8 characters');
      return;
    }
    if (password != confirmPassword) {
      _showError('Passwords do not match');
      return;
    }

    print('[SignUp] Attempting email/password signup: $email, username: $username');
    
    try {
      final ok = await ref
          .read(sessionControllerProvider.notifier)
          .signUpWithEmail(email: email, password: password, username: username);
      
      if (!mounted) return;
      
      if (ok) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
        );
      } else {
        _showError('Sign up failed. Please try again.');
      }
    } catch (e) {
      print('[SignUp] Error: $e');
      _showError('Sign up failed: $e');
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final session = ref.read(sessionControllerProvider);
    if (session.loading) return;

    final ok = await ref
        .read(sessionControllerProvider.notifier)
        .signInWithGoogle();
    if (!mounted) return;

    if (ok) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
      );
    } else {
      final message =
          ref.read(sessionControllerProvider).error ?? 'Google sign-in failed';
      _showError(message);
    }
  }

  Future<void> _handleGuestSignIn() async {
    final session = ref.read(sessionControllerProvider);
    if (session.loading) return;

    final ok =
        await ref.read(sessionControllerProvider.notifier).signInAsGuest();
    if (!mounted) return;

    if (ok) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    final loading = session.loading;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF111827), Color(0xFF090B10)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const Icon(
                    Icons.sports_cricket,
                    size: 56,
                    color: Colors.amber,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'IPL Auction Arena',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Real-time multiplayer bidding',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  GlassCard(
                    child: Column(
                      children: [
                        TabBar(
                          controller: _tabController,
                          tabs: const [
                            Tab(text: 'Login'),
                            Tab(text: 'Sign Up'),
                          ],
                        ),
                        SizedBox(
                          height: 320,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              // LOGIN TAB
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    TextField(
                                      controller: _loginEmailController,
                                      keyboardType:
                                          TextInputType.emailAddress,
                                      enabled: !loading,
                                      decoration: const InputDecoration(
                                        labelText: 'Email',
                                        prefixIcon: Icon(Icons.email),
                                        hintText: 'you@example.com',
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: _loginPasswordController,
                                      enabled: !loading,
                                      obscureText: _obscureLoginPassword,
                                      decoration: InputDecoration(
                                        labelText: 'Password',
                                        prefixIcon: const Icon(Icons.lock),
                                        suffixIcon: IconButton(
                                          icon: Icon(_obscureLoginPassword
                                              ? Icons.visibility_off
                                              : Icons.visibility),
                                          onPressed: () {
                                            setState(() {
                                              _obscureLoginPassword =
                                                  !_obscureLoginPassword;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    NeonButton(
                                      label: loading ? 'Logging in...' : 'Login',
                                      onTap:
                                          loading ? null : _handleLogin,
                                      icon: Icons.login,
                                    ),
                                  ],
                                ),
                              ),
                              // SIGNUP TAB
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      TextField(
                                        controller: _signupUsernameController,
                                        enabled: !loading,
                                        maxLength: 18,
                                        decoration: const InputDecoration(
                                          labelText: 'Username',
                                          prefixIcon: Icon(Icons.person),
                                          hintText: 'Your display name',
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: _signupEmailController,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        enabled: !loading,
                                        decoration: InputDecoration(
                                          labelText: 'Email',
                                          prefixIcon: const Icon(Icons.email),
                                          hintText: 'you@example.com',
                                          suffixIcon: IconButton(
                                            icon: const Icon(Icons.refresh),
                                            onPressed: _generateTestEmail,
                                            tooltip: 'Generate test email',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: Padding(
                                          padding: const EdgeInsets.only(right: 8),
                                          child: Text(
                                            'Tip: Click refresh icon for unique test email',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(color: Colors.grey),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextField(
                                        controller: _signupPasswordController,
                                        enabled: !loading,
                                        obscureText: _obscureSignupPassword,
                                        decoration: InputDecoration(
                                          labelText: 'Password',
                                          prefixIcon: const Icon(Icons.lock),
                                          suffixIcon: IconButton(
                                            icon: Icon(_obscureSignupPassword
                                                ? Icons.visibility_off
                                                : Icons.visibility),
                                            onPressed: () {
                                              setState(() {
                                                _obscureSignupPassword =
                                                    !_obscureSignupPassword;
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller:
                                            _signupConfirmPasswordController,
                                        enabled: !loading,
                                        obscureText:
                                            _obscureSignupConfirmPassword,
                                        decoration: InputDecoration(
                                          labelText: 'Confirm Password',
                                          prefixIcon: const Icon(Icons.lock),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                                _obscureSignupConfirmPassword
                                                    ? Icons.visibility_off
                                                    : Icons.visibility),
                                            onPressed: () {
                                              setState(() {
                                                _obscureSignupConfirmPassword =
                                                    !_obscureSignupConfirmPassword;
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      NeonButton(
                                        label: loading
                                            ? 'Creating Account...'
                                            : 'Sign Up',
                                        onTap:
                                            loading ? null : _handleSignUp,
                                        icon: Icons.person_add,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'OR',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  NeonButton(
                    label: loading ? 'Connecting...' : 'Continue with Google',
                    onTap: loading ? null : _handleGoogleSignIn,
                    icon: Icons.login,
                  ),
                  const SizedBox(height: 12),
                  NeonButton(
                    label: loading ? 'Loading...' : 'Continue as Guest',
                    onTap: loading ? null : _handleGuestSignIn,
                    icon: Icons.person,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

