import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gamer_flick/repositories/auth/auth_repository.dart';
import 'package:gamer_flick/repositories/user/user_repository.dart';
import 'package:gamer_flick/models/core/profile.dart';

/// Represents the state of authentication including the user and their profile.
class AppAuthState {
  final User? user;
  final Profile? profile;
  final bool isLoading;
  final String? error;

  AppAuthState({
    this.user,
    this.profile,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => user != null;

  AppAuthState copyWith({
    User? user,
    Profile? profile,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AppAuthState(
      user: user ?? this.user,
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// A Riverpod [AsyncNotifier] that manages authentication state and user profile.
class AuthNotifier extends AsyncNotifier<AppAuthState> {
  late final IAuthRepository _authRepository;
  late final IUserRepository _userRepository;
  StreamSubscription<AuthState>? _authStateSubscription;

  @override
  FutureOr<AppAuthState> build() async {
    _authRepository = ref.watch(authRepositoryProvider);
    _userRepository = ref.watch(userRepositoryProvider);

    // Initial auth state
    final currentUser = _authRepository.currentUser;
    
    // Setup listener for future changes
    _listenToAuthState();

    if (currentUser != null) {
      final profile = await _userRepository.getProfile(currentUser.id);
      return AppAuthState(user: currentUser, profile: profile);
    }

    return AppAuthState();
  }

  void _listenToAuthState() {
    _authStateSubscription?.cancel();
    _authStateSubscription = _authRepository.authStateChanges.listen((data) async {
      final session = data.session;
      final event = data.event;

      if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.tokenRefreshed) {
        if (session != null) {
          final profile = await _userRepository.getProfile(session.user.id);
          state = AsyncValue.data(AppAuthState(user: session.user, profile: profile));
        }
      } else if (event == AuthChangeEvent.signedOut) {
        state = AsyncValue.data(AppAuthState());
      }
    });
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.signInWithEmail(email, password);
      // Listener handles state update
    } catch (e) {
      state = AsyncValue.data(AppAuthState(error: e.toString()));
    }
  }

  Future<void> signUp(String email, String password, {String? username}) async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.signUpWithEmail(email, password, username: username);
      // Listener handles state update
    } catch (e) {
      state = AsyncValue.data(AppAuthState(error: e.toString()));
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.signOut();
      state = AsyncValue.data(AppAuthState());
    } catch (e) {
      state = AsyncValue.data(AppAuthState(error: e.toString()));
    }
  }

  Future<void> resetPassword(String email) async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.resetPassword(email);
      state = AsyncValue.data(state.value?.copyWith(isLoading: false) ?? AppAuthState());
    } catch (e) {
      state = AsyncValue.data(AppAuthState(error: e.toString()));
    }
  }

  void clearError() {
    if (state.hasValue) {
      state = AsyncValue.data(state.value!.copyWith(clearError: true));
    }
  }
}

/// Global provider for the [AuthNotifier].
final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, AppAuthState>(AuthNotifier.new);

/// Provider for the current user object.
final currentUserProvider = Provider<User?>((ref) => ref.watch(authNotifierProvider).value?.user);

/// Provider for the current user's profile.
final currentProfileProvider = Provider<Profile?>((ref) => ref.watch(authNotifierProvider).value?.profile);

/// Provider for checking authentication status.
final isAuthenticatedProvider = Provider<bool>((ref) => ref.watch(authNotifierProvider).value?.isAuthenticated ?? false);
