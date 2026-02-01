import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamer_flick/providers/app/premium_provider.dart';
import 'package:gamer_flick/services/user/premium_service.dart';

class PremiumScreen extends ConsumerWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final premiumState = ref.watch(premiumProvider);
    final premiumService = PremiumService();
    return Scaffold(
      appBar: AppBar(title: const Text('GamerFlick Premium')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Text(
                  'Unlock Premium',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Access pro features to level up your GamerFlick experience.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                _BenefitsGrid(),
                const SizedBox(height: 24),
                premiumState.when(
                  data: (isPremium) => Column(
                    children: [
                      if (isPremium)
                        ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.verified),
                          label: const Text('You are Premium'),
                        )
                      else ...[
                        ElevatedButton(
                          onPressed: () =>
                              premiumService.openExternalCheckoutUrl(
                            'https://buy.stripe.com/test_dummy',
                          ),
                          child: const Text('Upgrade - Monthly'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () =>
                              premiumService.openExternalCheckoutUrl(
                            'https://buy.stripe.com/test_dummy_yearly',
                          ),
                          child: const Text('Upgrade - Yearly (Save 20%)'),
                        ),
                      ],
                    ],
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Column(
                    children: [
                      Text('Error: $e'),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () =>
                            ref.read(premiumProvider.notifier).refresh(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Cancel anytime. Restores automatically on your devices.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BenefitsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = <_Benefit>[
      _Benefit(Icons.auto_awesome, 'Smart Recommendations',
          'AI-powered content and community suggestions'),
      _Benefit(Icons.ondemand_video, '4K Streams',
          'Broadcast and watch in crystal-clear 4K'),
      _Benefit(Icons.movie_filter, 'Unlimited Clips',
          'No daily limits on posting reels'),
      _Benefit(Icons.workspace_premium, 'VIP Communities',
          'Exclusive access to premium-only groups'),
      _Benefit(Icons.emoji_events, 'Real-Prize Tournaments',
          'Join tournaments with real prize pools'),
      _Benefit(Icons.card_giftcard, 'Monthly Loot Drops',
          'New items and rewards every month'),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 3.4,
      ),
      itemBuilder: (context, index) {
        final b = items[index];
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(b.icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.title,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(b.subtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Benefit {
  final IconData icon;
  final String title;
  final String subtitle;
  _Benefit(this.icon, this.title, this.subtitle);
}
