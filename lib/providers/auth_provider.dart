import 'package:flutter/material.dart';
// APPWRITE: import 'package:appwrite/models.dart' as models;
// APPWRITE: import '../services/appwrite_service.dart';
import '../services/google_oauth_service.dart';
import '../models/game_models.dart';

/// ============================================================
/// DUMMY MODE ENABLED - Uncomment APPWRITE lines for production
/// ============================================================
class AuthProvider with ChangeNotifier {
  // APPWRITE: final AppwriteService _appwriteService = AppwriteService();
  // APPWRITE: models.User? _currentUser;
  final GoogleOAuthService _googleOAuthService = GoogleOAuthService();
  
  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _error;

  // APPWRITE: models.User? get currentUser => _currentUser;
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  // APPWRITE: bool get isAuthenticated => _currentUser != null;
  bool get isAuthenticated => _userProfile != null; // DUMMY MODE

  Future<void> checkAuthStatus() async {
    try {
      _isLoading = true;
      notifyListeners();

      /* APPWRITE:
      _currentUser = await _appwriteService.getCurrentUser();
      if (_currentUser != null) {
        await _loadUserProfile();
      }
      */
      
      // DUMMY: Simulate no existing session
      await Future.delayed(const Duration(milliseconds: 500));
      _userProfile = null;
      
    } catch (e) {
      // APPWRITE: _currentUser = null;
      _userProfile = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      /* APPWRITE:
      await _appwriteService.login(email, password);
      _currentUser = await _appwriteService.getCurrentUser();
      await _loadUserProfile();
      */
      
      // DUMMY: Simulate login
      await Future.delayed(const Duration(seconds: 1));
      _userProfile = UserProfile(
        id: 'user_dummy_123',
        username: email.split('@').first,
        matchesPlayed: 12,
        matchesWon: 5,
        totalCoins: 450,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String email, String password, String username) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      /* APPWRITE:
      _currentUser = await _appwriteService.register(email, password, username);
      await _appwriteService.createUserProfile(
        userId: _currentUser!.$id,
        username: username,
      );
      await _appwriteService.login(email, password);
      await _loadUserProfile();
      */
      
      // DUMMY: Simulate registration
      await Future.delayed(const Duration(seconds: 1));
      _userProfile = UserProfile(
        id: 'user_new_${DateTime.now().millisecondsSinceEpoch}',
        username: username,
        matchesPlayed: 0,
        matchesWon: 0,
        totalCoins: 0,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginAsGuest() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      /* APPWRITE:
      _currentUser = await _appwriteService.createAnonymousSession();
      final guestName = 'Guest_\${_currentUser!.\$id.substring(0, 6)}';
      await _appwriteService.createUserProfile(
        userId: _currentUser!.$id,
        username: guestName,
      );
      await _loadUserProfile();
      */
      
      // DUMMY: Simulate guest login
      await Future.delayed(const Duration(seconds: 1));
      final guestId = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
      _userProfile = UserProfile(
        id: 'guest_$guestId',
        username: 'Guest_$guestId',
        matchesPlayed: 0,
        matchesWon: 0,
        totalCoins: 0,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign in with Google
  /// Returns true on success, false on failure
  /// Sets _error with user-friendly error message
  Future<bool> loginWithGoogle() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('🚀 Initiating Google Sign-In...');

      // Ensure Google OAuth service is initialized
      _googleOAuthService.init();

      // Call Google OAuth service
      final result = await _googleOAuthService.signInWithGoogle();

      if (!result['success']) {
        throw Exception('OAuth sign-in failed');
      }

      // Create user profile from OAuth result
      final userData = result['user'] as Map<String, dynamic>;
      _userProfile = UserProfile(
        id: userData['id'] ?? 'oauth_user',
        username: userData['name'] ?? userData['email'] ?? 'Google User',
        matchesPlayed: 0,
        matchesWon: 0,
        totalCoins: 0,
      );

      print('✅ Google Sign-In successful');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Google Sign-In error: $e');

      // Set user-friendly error message
      if (e is GoogleOAuthException) {
        _error = e.userMessage;
      } else {
        _error = 'Google sign-in failed. Please try again.';
      }

      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      // APPWRITE: await _appwriteService.logout();
      // APPWRITE: _currentUser = null;
      
      // DUMMY: Clear profile
      _userProfile = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /* APPWRITE:
  Future<void> _loadUserProfile() async {
    if (_currentUser == null) return;
    try {
      final doc = await _appwriteService.getUserProfile(_currentUser!.\$id);
      _userProfile = UserProfile.fromMap(doc.data, doc.\$id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }
  */

  Future<void> updateProfile(Map<String, dynamic> data) async {
    /* APPWRITE:
    if (_currentUser == null) return;
    try {
      await _appwriteService.updateUserProfile(_currentUser!.\$id, data);
      await _loadUserProfile();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
    */
    
    // DUMMY: Update local profile
    if (_userProfile != null && data.containsKey('username')) {
      _userProfile = _userProfile!.copyWith(
        username: data['username'] ?? _userProfile!.username,
      );
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
