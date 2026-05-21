import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ipl_auction_game/models/user_model.dart';
import 'package:ipl_auction_game/providers/app_providers.dart';

class SessionState {
  const SessionState({
    this.uid,
    this.accountEmail,
    this.user,
    this.loading = false,
    this.error,
  });

  final String? uid;
  final String? accountEmail;
  final UserModel? user;
  final bool loading;
  final String? error;

  SessionState copyWith({
    String? uid,
    String? accountEmail,
    UserModel? user,
    bool? loading,
    String? error,
  }) {
    return SessionState(
      uid: uid ?? this.uid,
      accountEmail: accountEmail ?? this.accountEmail,
      user: user ?? this.user,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class SessionController extends StateNotifier<SessionState> {
  SessionController(this._ref) : super(const SessionState());

  final Ref _ref;

  Future<void> bootstrap() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final auth = _ref.read(authServiceProvider);
      final account = await auth.getCurrentUserOrNull();
      final uid = account?.$id;
      if (uid == null) {
        state = state.copyWith(loading: false, uid: null, user: null);
        return;
      }

      final profile = await _ref.read(databaseServiceProvider).getUser(uid);
      state = state.copyWith(
        uid: uid,
        accountEmail: account?.email,
        user: profile,
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(loading: true, error: null);
    try {
      print('[OAuth] Starting Google sign-in...');
      final account = await _ref.read(authServiceProvider).signInWithGoogle();
      if (account == null) {
        print('[OAuth] Account is null after sign-in');
        state = state.copyWith(
          loading: false,
          error: 'Google sign-in was cancelled or failed',
        );
        return false;
      }

      print('[OAuth] Account ID: ${account.$id}, Email: ${account.email}, Name: ${account.name}');

      // Create user in users collection
      final initialUser = UserModel(
        userId: account.$id,
        username: account.name,
        email: account.email,
      );
      
      print('[OAuth] Creating user in users collection...');
      try {
        await _ref.read(databaseServiceProvider).upsertUser(initialUser);
        print('[OAuth] User created in users collection successfully');
      } catch (dbError) {
        print('[OAuth] Error creating user: $dbError');
        throw dbError;
      }

      state = state.copyWith(
        uid: account.$id,
        accountEmail: account.email,
        user: initialUser,
        loading: false,
      );
      print('[OAuth] Sign-in complete, returning true');
      return true;
    } catch (e) {
      print('[OAuth] ERROR: $e');
      state = state.copyWith(loading: false, error: 'Sign-in failed: $e');
      return false;
    }
  }

  Future<bool> signInAsGuest() async {
    state = state.copyWith(loading: true, error: null);
    try {
      print('[Guest] Starting guest sign-in...');
      final guestId = 'guest_${DateTime.now().millisecondsSinceEpoch}';
      final guestUser = UserModel(
        userId: guestId,
        username: 'Guest User',
        email: 'guest@localhost',
        createdAt: DateTime.now(),
      );

      state = state.copyWith(
        uid: guestId,
        user: guestUser,
        loading: false,
      );
      print('[Guest] Guest sign-in complete');
      return true;
    } catch (e) {
      print('[Guest] ERROR: $e');
      state = state.copyWith(loading: false, error: 'Guest sign-in failed: $e');
      return false;
    }
  }

  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String username,
  }) async {
    state = state.copyWith(loading: true, error: null);
    try {
      print('[EmailSignUp] Starting signup: $email');
      
      // Check if email already registered in database
      final existingUserByEmail = await _checkUserByEmail(email);
      if (existingUserByEmail != null) {
        print('[EmailSignUp] Email already registered: $email');
        state = state.copyWith(
          loading: false,
          error: 'This email is already registered. Please try logging in or use a different email.',
        );
        return false;
      }
      
      final account = await _ref.read(authServiceProvider).signUpWithEmail(
            email: email,
            password: password,
            username: username,
          );

      if (account == null) {
        print('[EmailSignUp] Account is null after signup');
        state = state.copyWith(
          loading: false,
          error: 'Sign-up failed',
        );
        return false;
      }

      print('[EmailSignUp] Account created: ${account.$id}');

      final user = UserModel(
        userId: account.$id,
        username: username,
        email: email,
      );

      state = state.copyWith(
        uid: account.$id,
        accountEmail: email,
        user: user,
        loading: false,
      );
      print('[EmailSignUp] Sign-up complete');
      return true;
    } catch (e) {
      print('[EmailSignUp] ERROR: $e');
      state = state.copyWith(loading: false, error: 'Sign-up failed: $e');
      return false;
    }
  }

  Future<UserModel?> _checkUserByEmail(String email) async {
    try {
      // In a real app, you'd query the database for existing users by email
      // For now, return null to allow signup
      return null;
    } catch (e) {
      print('[Session] Error checking user by email: $e');
      return null;
    }
  }

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(loading: true, error: null);
    try {
      print('[EmailSignIn] Starting login: $email');
      final account = await _ref.read(authServiceProvider).signInWithEmail(
            email: email,
            password: password,
          );

      if (account == null) {
        print('[EmailSignIn] Account is null after login');
        state = state.copyWith(
          loading: false,
          error: 'Login failed',
        );
        return false;
      }

      print('[EmailSignIn] Account logged in: ${account.$id}');

      // Fetch user profile from database
      final profile = await _ref.read(databaseServiceProvider).getUser(account.$id);
      
      final user = profile ?? UserModel(
        userId: account.$id,
        username: account.name,
        email: email,
      );

      state = state.copyWith(
        uid: account.$id,
        accountEmail: email,
        user: user,
        loading: false,
      );
      print('[EmailSignIn] Login complete');
      return true;
    } catch (e) {
      print('[EmailSignIn] ERROR: $e');
      state = state.copyWith(loading: false, error: 'Login failed: $e');
      return false;
    }
  }

  Future<bool> saveProfile({
    required String username,
    required String email,
    String? avatarUrl,
    bool? soundEnabled,
    bool? darkModeEnabled,
  }) async {
    final uid = state.uid;
    if (uid == null) {
      return false;
    }

    state = state.copyWith(loading: true, error: null);
    try {
      final currentUser = state.user;
      final updatedUser = UserModel(
        userId: uid,
        username: username,
        email: email,
        avatarUrl: avatarUrl ?? currentUser?.avatarUrl ?? '',
        matchesPlayed: currentUser?.matchesPlayed ?? 0,
        matchesWon: currentUser?.matchesWon ?? 0,
        totalCoins: currentUser?.totalCoins ?? 0,
        soundEnabled: soundEnabled ?? currentUser?.soundEnabled ?? true,
        darkModeEnabled: darkModeEnabled ?? currentUser?.darkModeEnabled ?? false,
      );

      await _ref.read(databaseServiceProvider).upsertUser(updatedUser);
      
      state = state.copyWith(user: updatedUser, loading: false);
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      return false;
    }
  }
}

final sessionControllerProvider =
    StateNotifierProvider<SessionController, SessionState>((ref) {
  return SessionController(ref);
});
