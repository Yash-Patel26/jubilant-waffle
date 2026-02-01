import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamer_flick/repositories/storage/local_storage_repository.dart';
import 'package:gamer_flick/services/core/navigation_service.dart';

class AuthListener extends ConsumerStatefulWidget {
  final Widget child;
  const AuthListener({super.key, required this.child});

  @override
  ConsumerState<AuthListener> createState() => _AuthListenerState();
}

class _AuthListenerState extends ConsumerState<AuthListener> {
  late final StreamSubscription<AuthState> _authSub;

  @override
  void initState() {
    super.initState();
    _authSub =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final event = data.event;

      // When tokens refresh, nothing to do as supabase_flutter persists session internally
      if (event == AuthChangeEvent.tokenRefreshed) {
        return;
      }

      if (event == AuthChangeEvent.signedOut) {
        // Clear saved credentials when user is signed out
        try {
          final storageRepo = ref.read(localStorageRepositoryProvider);
          await storageRepo.setBool('remember_me', false);
          await storageRepo.remove('saved_email');
          await storageRepo.removeSecureString('saved_password');
        } catch (e) {
          // Silently handle errors to avoid breaking auth flow
        }

        // If signed out (e.g., refresh token expired), navigate to login
        if (mounted) {
          navigatorKey.currentState
              ?.pushNamedAndRemoveUntil('/', (route) => false);
        }
      }
    });
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
