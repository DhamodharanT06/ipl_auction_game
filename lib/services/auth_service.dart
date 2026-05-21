import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart' as enums;
import 'package:appwrite/models.dart' as models;
import 'package:flutter/foundation.dart';
import 'package:ipl_auction_game/models/user_model.dart';
import 'package:ipl_auction_game/services/database_service.dart';

class AuthService {
  AuthService(this._account, this._databaseService);

  final Account _account;
  final DatabaseService _databaseService;

  Future<models.User?> getCurrentUserOrNull() async {
    try {
      await _account.getSession(sessionId: 'current');
      return _account.get();
    } on AppwriteException {
      return null;
    }
  }

  Future<models.User?> signInWithGoogle() async {
    try {
      final successUrl = kIsWeb
          ? Uri.base.origin
          : 'app.dynamicdragon.ipl_auction://oauth/callback';
      final failureUrl = kIsWeb
          ? Uri.base.origin
          : 'app.dynamicdragon.ipl_auction://oauth/failure';

      await _account.createOAuth2Session(
        provider: enums.OAuthProvider.google,
        scopes: const ['email', 'profile'],
        success: successUrl,
        failure: failureUrl,
      );

      // Wait a moment for session to be fully established after OAuth
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Retry getting user with exponential backoff
      for (int i = 0; i < 3; i++) {
        try {
          final user = await getCurrentUserOrNull();
          if (user != null) {
            print('OAuth: User retrieved on attempt ${i + 1}');
            return user;
          }
        } catch (e) {
          print('OAuth: Attempt ${i + 1} failed: $e');
          if (i < 2) {
            await Future.delayed(Duration(milliseconds: 300 * (i + 1)));
          }
        }
      }
      
      print('OAuth: Failed to retrieve user after 3 attempts');
      return null;
    } on AppwriteException catch (e) {
      print('OAuth Error: $e');
      rethrow;
    }
  }

  Future<models.User?> signUpWithEmail({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      print('[AuthService] ============ SIGNUP START ============');
      print('[AuthService] Email: $email');
      print('[AuthService] Username: $username');
      print('[AuthService] Password length: ${password.length}');
      
      // Validate inputs
      if (email.isEmpty || !email.contains('@')) {
        throw Exception('Invalid email format - must contain @');
      }
      if (password.length < 8) {
        throw Exception('Password must be at least 8 characters, got ${password.length}');
      }
      if (username.isEmpty || username.length < 2) {
        throw Exception('Username must be at least 2 characters');
      }

      // Check for special characters that might cause issues
      print('[AuthService] Email validation: OK');
      print('[AuthService] Password validation: OK');
      print('[AuthService] Username validation: OK');

      // Create user account with unique ID
      final userId = ID.unique();
      print('[AuthService] Generated userId: $userId');
      print('[AuthService] Attempting to create account...');
      
      final user = await _account.create(
        userId: userId,
        email: email,
        password: password,
        name: username,
      );
      
      print('[AuthService] ✓ Account created: ${user.$id}');
      print('[AuthService] Account email verified: ${user.emailVerification}');

      // Appwrite account creation does not automatically create a login session.
      // Create session so authenticated APIs (e.g., lobby/database) work right away.
      await _account.createEmailPasswordSession(
        email: email,
        password: password,
      );
      print('[AuthService] ✓ Login session created after signup');

      // Upsert user profile in database
      print('[AuthService] Saving user to database...');
      await _databaseService.upsertUser(
        UserModel(
          userId: user.$id,
          username: username,
          email: email,
        ),
      );
      print('[AuthService] ✓ User profile saved to database');
      print('[AuthService] ============ SIGNUP SUCCESS ============');

      return user;
    } on AppwriteException catch (e) {
      print('[AuthService] ✗ Appwrite Exception: ${e.code}');
      print('[AuthService] ✗ Message: ${e.message}');
      
      // More specific error handling
      final msg = e.message?.toLowerCase() ?? '';
      if (msg.contains('email') || msg.contains('already')) {
        throw Exception('Email already registered. Please try another email or log in.');
      }
      if (msg.contains('password')) {
        throw Exception('Password does not meet requirements. Use 8+ characters with letters and numbers.');
      }
      
      print('[AuthService] ============ SIGNUP FAILED ============');
      rethrow;
    } catch (e) {
      print('[AuthService] ✗ General Error: $e');
      print('[AuthService] ============ SIGNUP FAILED ============');
      rethrow;
    }
  }

  Future<models.User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      print('[AuthService] ============ SIGNIN START ============');
      print('[AuthService] Email: $email');

      // Check if already authenticated
      final existingUser = await getCurrentUserOrNull();
      if (existingUser != null) {
        print('[AuthService] User already authenticated: ${existingUser.$id}');
        return existingUser;
      }

      print('[AuthService] No active session - attempting to create session...');
      
      // Create email/password session
      print('[AuthService] Calling createEmailPasswordSession...');
      await _account.createEmailPasswordSession(
        email: email,
        password: password,
      );
      print('[AuthService] ✓ Session created successfully');

      // Get the authenticated user
      final user = await _account.get();
      print('[AuthService] ✓ User retrieved: ${user.$id}');
      print('[AuthService] ============ SIGNIN SUCCESS ============');
      
      return user;
    } on AppwriteException catch (e) {
      print('[AuthService] ✗ Appwrite Exception: ${e.code}');
      print('[AuthService] ✗ Message: ${e.message}');
      print('[AuthService] ============ SIGNIN FAILED ============');
      
      final msg = e.message?.toLowerCase() ?? '';
      if (msg.contains('email') || msg.contains('not found')) {
        throw Exception('Email not found or account not created. Please sign up first.');
      }
      if (msg.contains('password') || msg.contains('invalid')) {
        throw Exception('Invalid email or password. Please check and try again.');
      }
      throw Exception('Login failed: ${e.message}');
    } catch (e) {
      print('[AuthService] ✗ Unexpected error: $e');
      print('[AuthService] ============ SIGNIN FAILED ============');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _account.deleteSession(sessionId: 'current');
  }
}
