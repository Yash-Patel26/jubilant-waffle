import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../profile/edit_profile_screen.dart';
import '../auth/login_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamer_flick/providers/app/theme_provider.dart';
import 'package:gamer_flick/repositories/storage/local_storage_repository.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:gamer_flick/services/user/premium_service.dart';

final loadingProvider = StateProvider<bool>((ref) => false);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final loading = ref.watch(loadingProvider);
    return Stack(
      children: [
        Scaffold(
          backgroundColor:
              theme.colorScheme.surface, // Use theme background color
          appBar: AppBar(
            elevation: 0, // Remove elevation for flat, modern look
            backgroundColor:
                theme.colorScheme.surface, // Use surface color for AppBar
            foregroundColor: theme
                .colorScheme.onSurface, // Ensure title and icons are visible
            title: Text(
              'Settings',
              style: theme.appBarTheme.titleTextStyle?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontSize: 22, // Adjusted font size
                  ) ??
                  const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                      color: Colors.white), // Fallback
            ),
            iconTheme: IconThemeData(
              color: theme.colorScheme
                  .onSurface, // Ensure back button color is consistent
            ),
          ),
          body: FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final appVersion = snapshot.data?.version ?? '3.0.0';
              return ListView(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Text('Account',
                        style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.colorScheme
                                  .primary, // Accent color for section titles
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ) ??
                            const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                  ),
                  _buildSettingsTile(
                    context,
                    theme,
                    leadingIcon: Icons.workspace_premium,
                    leadingIconColor: theme.colorScheme.secondary,
                    title: 'GamerFlick Premium',
                    subtitle: 'Unlock Smart Recommendations and more',
                    onTap: () => PremiumService().openUpgrade(context),
                  ),
                  _buildSettingsTile(
                    context,
                    theme,
                    leadingIcon: Icons.person,
                    title: 'Edit Profile',
                    onTap: () async {
                      final user = Supabase.instance.client.auth.currentUser;
                      if (user == null) return;
                      final profile = await _fetchUserProfile();
                      if (profile == null) return;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              EditProfileScreen(userProfile: profile),
                        ),
                      );
                    },
                  ),
                  _buildSettingsTile(
                    context,
                    theme,
                    leadingIcon: Icons.lock,
                    title: 'Change Password',
                    onTap: () => _changePassword(context, ref),
                  ),
                  _buildSettingsTile(
                    context,
                    theme,
                    leadingIcon: Icons.logout,
                    title: 'Logout',
                    onTap: () => _logout(context, ref),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Text('Theme',
                        style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.colorScheme
                                  .primary, // Accent color for section titles
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ) ??
                            const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                  ),
                  _buildThemeToggleTile(
                      context, theme, themeMode, ref), // Extracted theme toggle
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Text('App Info',
                        style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.colorScheme
                                  .primary, // Accent color for section titles
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ) ??
                            const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                  ),
                  _buildSettingsTile(
                    context,
                    theme,
                    leadingIcon: Icons.info_outline,
                    title: 'About',
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'GamerFlick',
                        applicationVersion: appVersion,
                        applicationLegalese: '© 2025 GamerFlick',
                      );
                    },
                  ),
                  _buildSettingsTile(
                    context,
                    theme,
                    leadingIcon: Icons.support_agent,
                    title: 'Contact Support',
                    onTap: () => _contactSupport(context),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Text('App Updates',
                        style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.colorScheme
                                  .primary, // Accent color for section titles
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ) ??
                            const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                  ),
                  _buildSettingsTile(
                    context,
                    theme,
                    leadingIcon: Icons.new_releases,
                    leadingIconColor: theme.colorScheme.primary,
                    title: 'What\'s New',
                    subtitle: 'Check out the latest features',
                    onTap: () => _showWhatsNew(context, appVersion),
                  ),
                  _buildVersionTile(
                      context, theme, appVersion), // Extracted version tile
                ],
              );
            },
          ),
        ),
        if (loading)
          Container(
            color: theme.shadowColor.withOpacity(0.2),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildSettingsTile(
    BuildContext context,
    ThemeData theme, {
    required IconData leadingIcon,
    Color? leadingIconColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest, // Card background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(leadingIcon,
            color: leadingIconColor ?? theme.colorScheme.onSurfaceVariant),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ) ??
              TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                    ) ??
                    TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.7)),
              )
            : null,
        onTap: onTap,
      ),
    );
  }

  Widget _buildThemeToggleTile(BuildContext context, ThemeData theme,
      ThemeMode themeMode, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest, // Card background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          'Theme',
          style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ) ??
              TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          themeMode == ThemeMode.system
              ? 'System Default'
              : themeMode == ThemeMode.light
                  ? 'Light'
                  : 'Dark',
          style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
              ) ??
              TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
        ),
        trailing: ToggleButtons(
          isSelected: [
            themeMode == ThemeMode.system,
            themeMode == ThemeMode.light,
            themeMode == ThemeMode.dark,
          ],
          onPressed: (int index) {
            final modes = [ThemeMode.system, ThemeMode.light, ThemeMode.dark];
            ref.read(themeModeProvider.notifier).setThemeMode(modes[index]);
          },
          borderRadius: BorderRadius.circular(8),
          fillColor: theme.colorScheme.primary, // Accent fill color
          selectedColor: theme.colorScheme.onPrimary, // Text color on accent
          color: theme.colorScheme.onSurfaceVariant, // Unselected text color
          borderColor:
              theme.colorScheme.outline.withOpacity(0.3), // Border color
          selectedBorderColor:
              theme.colorScheme.primary, // Selected border color
          children: const [
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8), // Adjusted padding
              child: Text('System'),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8), // Adjusted padding
              child: Text('Light'),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8), // Adjusted padding
              child: Text('Dark'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionTile(
      BuildContext context, ThemeData theme, String appVersion) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest, // Card background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(Icons.update,
            color: theme.colorScheme.secondary), // Use secondary color
        title: Text(
          'Version $appVersion',
          style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ) ??
              TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Latest version',
          style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
              ) ??
              TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 5), // Adjusted padding
          decoration: BoxDecoration(
            color: theme.colorScheme.tertiary, // Use tertiary accent color
            borderRadius: BorderRadius.circular(10), // More rounded
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.tertiary
                    .withOpacity(0.3), // Accent shadow
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            'NEW',
            style: TextStyle(
              color: theme.colorScheme.onTertiary, // Ensure readable color
              fontSize: 10,
              fontWeight: FontWeight.w800, // Even bolder
            ),
          ),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> _fetchUserProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;
    final data = await Supabase.instance.client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();
    return data;
  }

  Future<void> _changePassword(BuildContext context, WidgetRef ref) async {
    final theme = Theme.of(context);
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'New Password'),
            validator: (val) => val == null || val.length < 6
                ? 'Password must be at least 6 characters'
                : null,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(ctx, controller.text);
                }
              },
              child: const Text('Change')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      ref.read(loadingProvider.notifier).state = true;
      try {
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(password: result),
        );

        // Clear saved credentials since password has changed
        try {
          final storageRepo = ref.read(localStorageRepositoryProvider);
          await storageRepo.setBool('remember_me', false);
          await storageRepo.remove('saved_email');
          await storageRepo.removeSecureString('saved_password');
        } catch (e) {
          // Silently handle errors to avoid breaking password change flow
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Password changed! Please log in again with your new password.'),
              backgroundColor: theme.colorScheme.secondary),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: theme.colorScheme.error),
        );
      } finally {
        ref.read(loadingProvider.notifier).state = false;
      }
    }
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    ref.read(loadingProvider.notifier).state = true;

    // Clear saved credentials when logging out
    try {
      final storageRepo = ref.read(localStorageRepositoryProvider);
      await storageRepo.setBool('remember_me', false);
      await storageRepo.remove('saved_email');
      await storageRepo.removeSecureString('saved_password');
    } catch (e) {
      // Silently handle errors to avoid breaking logout flow
    }

    await Supabase.instance.client.auth.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
    ref.read(loadingProvider.notifier).state = false;
  }

  Future<void> _contactSupport(BuildContext context) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@gamerflick.in',
      query: 'subject=Support Request',
    );
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open email app.')),
      );
    }
  }

  void _showWhatsNew(BuildContext context, String appVersion) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.new_releases, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text("What's New in $appVersion"),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFeatureItem(
                context,
                icon: Icons.video_library,
                title: '🎬 Reels Feature',
                description:
                    'Brand new TikTok-style reels with vertical video playback, like, comment, and share functionality.',
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                context,
                icon: Icons.favorite,
                title: '❤️ Enhanced Interactions',
                description:
                    'Like, comment, and share reels with real-time updates and beautiful UI animations.',
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                context,
                icon: Icons.people,
                title: '👥 Share to Followers',
                description:
                    'Share your favorite reels directly with your followers through the new sharing system.',
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                context,
                icon: Icons.volume_up,
                title: '🔊 Audio Controls',
                description:
                    'Mute and unmute videos with easy-to-use controls and visual feedback.',
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                context,
                icon: Icons.play_circle_outline,
                title: '▶️ Auto-Play Videos',
                description:
                    'Videos automatically play when scrolled to and pause when scrolled away for better performance.',
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                context,
                icon: Icons.message,
                title: '💬 Real-time Comments',
                description:
                    'Add comments to reels with real-time updates and user profile information.',
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 16),
              _buildFeatureItem(
                context,
                icon: Icons.speed,
                title: '⚡ Performance Improvements',
                description:
                    'Optimized video loading, better memory management, and smoother scrolling experience.',
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                context,
                icon: Icons.palette,
                title: '🎨 UI/UX Enhancements',
                description:
                    'Modern TikTok-inspired design with improved animations, shadows, and visual feedback.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
