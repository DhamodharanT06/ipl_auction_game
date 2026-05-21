import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../parameters.dart';
import '../notifications.dart';
import 'home_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: iconGreen.withAlpha(100),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              SizedBox(height: size.height * 0.03),
              
              // Logo
              Hero(
                tag: 'app_logo',
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: iconGold, width: 2),
                  ),
                  child: Image.asset('assets/Logo_no_bg.png'),
                ),
              ),
              
              const SizedBox(height: 20),
              
              InkWell(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const HomePage()));
                },
                child: Text(
                  'IPL Auction Game',
                  style: TextStyle(
                    color: iconGold,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Tab Bar
              Container(
                decoration: BoxDecoration(
                  color: iconPurple.withAlpha(100),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: iconGold.withAlpha(100)),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: iconGold.withAlpha(80),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  labelColor: iconGold,
                  unselectedLabelColor: iconGold.withAlpha(150),
                  tabs: const [
                    Tab(text: 'Login'),
                    Tab(text: 'Register'),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Tab Views
              SizedBox(
                height: 360,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLoginForm(authProvider),
                    _buildRegisterForm(authProvider),
                  ],
                ),
              ),
              
              // Social Login - Google
              const SizedBox(height: 16),
              _buildGoogleButton(authProvider),
              
              // Guest Login Button
              const SizedBox(height: 8),
              _buildGuestButton(authProvider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(AuthProvider authProvider) {
    return Column(
      children: [
        _buildTextField(
          controller: _emailController,
          label: 'Email',
          icon: Icons.email,
          keyboardType: TextInputType.emailAddress,
        ),
        
        const SizedBox(height: 16),
        
        _buildTextField(
          controller: _passwordController,
          label: 'Password',
          icon: Icons.lock,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility : Icons.visibility_off,
              color: iconGold,
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
        ),
        
        const SizedBox(height: 24),
        
        if (authProvider.isLoading)
          CircularProgressIndicator(color: iconGold)
        else
          _buildActionButton('Login', () => _handleLogin(authProvider)),
        
        if (authProvider.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              authProvider.error!,
              style: TextStyle(color: Colors.red.shade300),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildRegisterForm(AuthProvider authProvider) {
    return Column(
      children: [
        _buildTextField(
          controller: _usernameController,
          label: 'Username',
          icon: Icons.person,
        ),
        
        const SizedBox(height: 16),
        
        _buildTextField(
          controller: _emailController,
          label: 'Email',
          icon: Icons.email,
          keyboardType: TextInputType.emailAddress,
        ),
        
        const SizedBox(height: 16),
        
        _buildTextField(
          controller: _passwordController,
          label: 'Password',
          icon: Icons.lock,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility : Icons.visibility_off,
              color: iconGold,
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
        ),
        
        const SizedBox(height: 24),
        
        if (authProvider.isLoading)
          CircularProgressIndicator(color: iconGold)
        else
          _buildActionButton('Register', () => _handleRegister(authProvider)),
        
        if (authProvider.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              authProvider.error!,
              style: TextStyle(color: Colors.red.shade300),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(color: iconGold),
      cursorColor: iconGold,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: iconGold.withAlpha(150)),
        prefixIcon: Icon(icon, color: iconGold),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: iconPurple.withAlpha(80),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: iconGold.withAlpha(100)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: iconGold.withAlpha(100)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: iconGold, width: 2),
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: iconGold, width: 1),
          color: iconGold.withAlpha(30),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: iconGold,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildGuestButton(AuthProvider authProvider) {
    return InkWell(
      onTap: authProvider.isLoading ? null : () => _handleGuestLogin(authProvider),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: iconGold.withAlpha(150), width: 1),
          color: iconPurple.withAlpha(50),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_outline, color: iconGold),
            const SizedBox(width: 8),
            Text(
              'Continue as Guest',
              style: TextStyle(
                color: iconGold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleButton(AuthProvider authProvider) {
    return InkWell(
      onTap: authProvider.isLoading ? null : () => _handleGoogleLogin(authProvider),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.red.shade300, width: 1),
          color: Colors.red.shade900.withAlpha(50),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (authProvider.isLoading)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.red.shade300),
                ),
              )
            else
              Text(
                'G',
                style: TextStyle(
                  color: Colors.red.shade300,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(width: 8),
            Text(
              'Sign in with Google',
              style: TextStyle(
                color: Colors.red.shade300,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogin(AuthProvider authProvider) async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      showError(context, 'Please fill in all fields');
      return;
    }
    
    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomePage(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          transitionsBuilder: (_, __, ___, child) => child,
        ),
      );
    }
  }

  Future<void> _handleRegister(AuthProvider authProvider) async {
    if (_usernameController.text.isEmpty || 
        _emailController.text.isEmpty || 
        _passwordController.text.isEmpty) {
      showError(context, 'Please fill in all fields');
      return;
    }
    
    if (_passwordController.text.length < 8) {
      showError(context, 'Password must be at least 8 characters');
      return;
    }
    
    final success = await authProvider.register(
      _emailController.text.trim(),
      _passwordController.text,
      _usernameController.text.trim(),
    );

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomePage(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          transitionsBuilder: (_, __, ___, child) => child,
        ),
      );
    }
  }

  Future<void> _handleGuestLogin(AuthProvider authProvider) async {
    final success = await authProvider.loginAsGuest();

    if (success && mounted) {
      showSuccess(context, 'Welcome, Guest!');
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomePage(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          transitionsBuilder: (_, __, ___, child) => child,
        ),
      );
    } else if (mounted && authProvider.error != null) {
      showError(context, authProvider.error!);
    }
  }

  Future<void> _handleGoogleLogin(AuthProvider authProvider) async {
    authProvider.clearError();
    
    final success = await authProvider.loginWithGoogle();

    if (success && mounted) {
      showSuccess(context, 'Welcome!');
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomePage(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          transitionsBuilder: (_, __, ___, child) => child,
        ),
      );
    } else if (mounted && authProvider.error != null) {
      showError(context, authProvider.error!);
    }
  }
}
