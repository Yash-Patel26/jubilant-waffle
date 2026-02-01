import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class PremiumService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<bool> isUserPremium({String? userId}) async {
    try {
      final uid = userId ?? _supabase.auth.currentUser?.id;
      if (uid == null) return false;
      final profile =
          await _supabase.from('profiles').select().eq('id', uid).maybeSingle();
      if (profile == null) return false;

      final isPremiumFlag = (profile['is_premium'] == true);
      final expiresAtStr = profile['premium_expires_at'] as String?;
      if (!isPremiumFlag) return false;
      if (expiresAtStr == null) return isPremiumFlag;
      final expiresAt = DateTime.tryParse(expiresAtStr);
      if (expiresAt == null) return isPremiumFlag;
      return DateTime.now().isBefore(expiresAt);
    } catch (_) {
      // If schema not yet migrated or any failure occurs, treat as not premium
      return false;
    }
  }

  Future<void> openUpgrade(BuildContext context) async {
    // Navigate to in-app paywall first
    if (context.mounted) {
      Navigator.of(context).pushNamed('/premium');
    }
  }

  Future<void> openExternalCheckoutUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
