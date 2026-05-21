import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:appwrite/enums.dart' as enums;
import '../config/appwrite_config.dart';

/// GoogleOAuthService
/// Handles Google OAuth authentication with Appwrite
class GoogleOAuthService {
  static final GoogleOAuthService _instance = GoogleOAuthService._internal();
  factory GoogleOAuthService() => _instance;
  GoogleOAuthService._internal();

  late Client client;
  late Account account;

  void init() {
    client = Client()
        .setEndpoint(AppwriteConfig.endpoint)
        .setProject(AppwriteConfig.projectId);
    account = Account(client);
  }

  /// Sign in with Google using Appwrite's native OAuth
  /// Appwrite handles the OAuth flow automatically
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      print('🔐 Starting Google OAuth with Appwrite...');

      // Use Appwrite's built-in createOAuth2Session
      // createOAuth2Session accepts provider string
      final Uri successUri = Uri.parse('${AppwriteConfig.endpoint}/auth/oauth2/callback/google/android');
      
      await account.createOAuth2Session(
        provider: enums.OAuthProvider.google,
        success: successUri.toString(),
        failure: successUri.toString(),
        scopes: ['profile', 'email'],
      );

      print('✅ OAuth session created');

      // Get current user info
      try {
        final user = await account.get();

        print('✅ Google OAuth successful - User: ${user.name}');

        return {
          'success': true,
          'user': {
            'id': user.$id,
            'name': user.name,
            'email': user.email,
          },
        };
      } catch (e) {
        print('❌ User fetch error: $e');
        throw GoogleOAuthException(
          code: 'USER_FETCH_ERROR',
          message: 'Failed to retrieve user information: $e',
        );
      }
    } on GoogleOAuthException {
      rethrow;
    } catch (e) {
      print('❌ Google OAuth error: $e');

      // Categorize error
      String errorCode = 'OAUTH_FAILED';
      String errorMessage = e.toString();

      if (errorMessage.contains('network') ||
          errorMessage.contains('Network') ||
          errorMessage.contains('timeout') ||
          errorMessage.contains('SocketException')) {
        errorCode = 'NETWORK_ERROR';
        errorMessage = 'Network connectivity issue';
      } else if (errorMessage.contains('cancel') ||
          errorMessage.contains('Cancel') ||
          errorMessage.contains('403')) {
        errorCode = 'CANCELLED';
        errorMessage = 'Sign-in was cancelled';
      } else if (errorMessage.contains('401') ||
          errorMessage.contains('unauthorized')) {
        errorCode = 'INVALID_CREDENTIALS';
        errorMessage = 'Invalid Google credentials';
      } else if (errorMessage.contains('400')) {
        errorCode = 'INVALID_REQUEST';
        errorMessage = 'Invalid OAuth request - check Appwrite OAuth settings';
      } else if (errorMessage.contains('provider')) {
        errorCode = 'PROVIDER_NOT_CONFIGURED';
        errorMessage = 'Google OAuth not configured in Appwrite';
      }

      throw GoogleOAuthException(
        code: errorCode,
        message: errorMessage,
      );
    }
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    try {
      await account.get();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      await account.deleteSession(sessionId: 'current');
      print('✅ Logged out successfully');
    } catch (e) {
      print('❌ Logout error: $e');
      rethrow;
    }
  }

  /// Get current session
  Future<models.Session?> getSession() async {
    try {
      final sessions = await account.listSessions();
      if (sessions.sessions.isNotEmpty) {
        return sessions.sessions.first;
      }
      return null;
    } catch (e) {
      print('❌ Session fetch error: $e');
      return null;
    }
  }
}

/// Custom exception for Google OAuth errors
class GoogleOAuthException implements Exception {
  final String code;
  final String message;

  GoogleOAuthException({
    required this.code,
    required this.message,
  });

  /// User-friendly error message
  String get userMessage {
    switch (code) {
      case 'NETWORK_ERROR':
        return 'Network error. Please check your internet connection.';
      case 'OAUTH_FAILED':
        return 'Google sign-in failed. Please try again.';
      case 'CANCELLED':
        return 'Sign-in was cancelled.';
      case 'INVALID_CREDENTIALS':
        return 'Invalid Google credentials. Please try again.';
      case 'INVALID_REQUEST':
        return 'Invalid request. Please contact support.';
      case 'USER_FETCH_ERROR':
        return 'Failed to retrieve user information. Please try again.';
      case 'PROVIDER_NOT_CONFIGURED':
        return 'Google OAuth is not configured. Please contact support.';
      default:
        return 'An error occurred: ${code.replaceAll('_', ' ')}';
    }
  }

  @override
  String toString() => 'GoogleOAuthException: $code - $message';
}
