import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gamer_flick/services/user/premium_service.dart';

final premiumProvider =
    StateNotifierProvider<PremiumNotifier, AsyncValue<bool>>(
  (ref) => PremiumNotifier(PremiumService()),
);

class PremiumNotifier extends StateNotifier<AsyncValue<bool>> {
  final PremiumService _premiumService;
  PremiumNotifier(this._premiumService) : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        state = const AsyncValue.data(false);
        return;
      }
      final isPremium = await _premiumService.isUserPremium(userId: user.id);
      state = AsyncValue.data(isPremium);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
