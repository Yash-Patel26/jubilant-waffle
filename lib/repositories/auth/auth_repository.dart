import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamer_flick/services/core/network_service.dart';
import 'package:gamer_flick/services/core/error_reporting_service.dart';
import 'package:gamer_flick/config/environment.dart';
import 'package:gamer_flick/providers/core/supabase_provider.dart';

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseAuthRepository(client: client);
});

abstract class IAuthRepository {
  User? get currentUser;
  bool get isAuthenticated;
  Stream<AuthState> get authStateChanges;
  
  Future<AuthResponse> signInWithEmail(String email, String password);
  Future<AuthResponse> signUpWithEmail(String email, String password, {String? username});
  Future<void> signInWithGoogle();
  Future<void> signOut();
  Future<void> resetPassword(String email);
  Future<void> updatePassword(String newPassword);
}

class SupabaseAuthRepository implements IAuthRepository {
  final SupabaseClient _client;
  final NetworkService _networkService;
  final ErrorReportingService _errorReportingService;

  SupabaseAuthRepository({
    required SupabaseClient client,
    NetworkService? networkService,
    ErrorReportingService? errorReportingService,
  })  : _client = client,
        _networkService = networkService ?? NetworkService(),
        _errorReportingService = errorReportingService ?? ErrorReportingService();

  @override
  User? get currentUser => _client.auth.currentUser;

  @override
  bool get isAuthenticated => _client.auth.currentUser != null;

  @override
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  @override
  Future<AuthResponse> signInWithEmail(String email, String password) async {
    return _networkService.executeWithRetry(
      operationName: 'AuthRepository.signInWithEmail',
      operation: () => _client.auth.signInWithPassword(email: email, password: password),
    );
  }

  @override
  Future<AuthResponse> signUpWithEmail(String email, String password, {String? username}) async {
    return _networkService.executeWithRetry(
      operationName: 'AuthRepository.signUpWithEmail',
      operation: () async {
        final response = await _client.auth.signUp(
          email: email,
          password: password,
          data: username != null ? {'username': username} : null,
        );

        if (response.user != null) {
          await _createUserProfile(response.user!, username);
        }

        return response;
      },
    );
  }

  Future<void> _createUserProfile(User user, String? username) async {
    try {
      String finalUsername = username ?? (user.email != null ? user.email!.split('@')[0] : 'User');

      final existingProfile = await _client
          .from('profiles')
          .select('username')
          .eq('username', finalUsername)
          .maybeSingle();

      if (existingProfile != null) {
        int counter = 1;
        String baseUsername = finalUsername;
        while (true) {
          finalUsername = '${baseUsername}_$counter';
          final check = await _client
              .from('profiles')
              .select('username')
              .eq('username', finalUsername)
              .maybeSingle();
          if (check == null) break;
          counter++;
        }
      }

      await _client.from('profiles').insert({
        'id': user.id,
        'username': finalUsername,
        'email': user.email,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      _errorReportingService.reportError('Failed to create profile during signup: $e', null);
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    return _networkService.executeWithRetry(
      operationName: 'AuthRepository.signInWithGoogle',
      operation: () => _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: '${Environment.googleAuthRedirectUrl}/google',
      ),
    );
  }

  @override
  Future<void> signOut() async {
    return _networkService.executeWithRetry(
      operationName: 'AuthRepository.signOut',
      operation: () => _client.auth.signOut(),
    );
  }

  @override
  Future<void> resetPassword(String email) async {
    return _networkService.executeWithRetry(
      operationName: 'AuthRepository.resetPassword',
      operation: () => _client.auth.resetPasswordForEmail(email),
    );
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    return _networkService.executeWithRetry(
      operationName: 'AuthRepository.updatePassword',
      operation: () => _client.auth.updateUser(UserAttributes(password: newPassword)),
    );
  }
}

