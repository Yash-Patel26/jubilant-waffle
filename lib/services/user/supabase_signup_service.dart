import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

class SupabaseSignupService {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<bool> emailExists(String email) async {
    final dynamic response = await supabase.auth.admin.listUsers();
    return response.users
        .any((user) => user.email?.toLowerCase() == email.toLowerCase());
  }

  Future<void> sendOtp(String email) async {
    await supabase.auth.signInWithOtp(email: email);
  }

  Future<bool> verifyOtp({required String email, required String otp}) async {
    final response = await supabase.auth.verifyOTP(
      type: OtpType.email,
      email: email,
      token: otp,
    );
    return response.session != null;
  }

  Future<AuthResponse> registerPasswordAccount({
    required String email,
    required String password,
  }) async {
    return await supabase.auth.signUp(email: email, password: password);
  }

  // Sets/updates password for the currently authenticated user (post-OTP)
  Future<void> setPasswordForCurrentUser(String password) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw AuthException('No authenticated user to set password for');
    }
    await supabase.auth.updateUser(UserAttributes(password: password));
  }

  Future<String> uploadAvatar({
    required String userId,
    required String filePath,
    required Uint8List bytes,
  }) async {
    final storagePath = 'profiles/$userId/avatar.png';
    await supabase.storage.from('avatars').uploadBinary(storagePath, bytes,
        fileOptions: const FileOptions(upsert: true));
    return supabase.storage.from('avatars').getPublicUrl(storagePath);
  }

  Future<void> storeProfileData({
    required String userId,
    required String username,
    required String email,
    required String? avatarUrl,
    required String? preferredGame,
    required String? gameId,
  }) async {
    // Check for unique username (case-insensitive)
    final usernameExists = await supabase
        .from('profiles')
        .select()
        .ilike('username', username)
        .maybeSingle();
    if (usernameExists != null && usernameExists['id'] != userId) {
      throw Exception('Username already exists.');
    }

    // Check for unique email (case-insensitive)
    final emailExists = await supabase
        .from('profiles')
        .select()
        .ilike('email', email)
        .maybeSingle();
    if (emailExists != null && emailExists['id'] != userId) {
      throw Exception('Email already exists.');
    }

    try {
      await supabase.from('profiles').upsert({
        'id': userId,
        'username': username,
        'email': email,
        'profile_picture_url': avatarUrl,
        'preferred_game': preferredGame,
        'gaming_id': gameId,
      });
    } on PostgrestException catch (e) {
      if (e.code == '409') {
        throw Exception('Username or email already exists.');
      } else {
        throw Exception(e.message ?? 'Unknown error');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
