import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamer_flick/providers/app/theme_provider.dart';
import '../../widgets/safe_scaffold.dart';

class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentThemeMode = ref.watch(themeModeProvider);
    final themeNotifier = ref.read(themeModeProvider.notifier);

    return SafeScaffold(
      appBar: AppBar(
        title: const Text('Theme Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Choose Your Theme',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select how you want GamerFlick to look. You can choose between light, dark, or follow your system settings.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 32),

            // Theme Options
            _buildThemeOption(
              context,
              ref,
              ThemeMode.light,
              currentThemeMode,
              themeNotifier,
              theme,
            ),
            const SizedBox(height: 16),
            _buildThemeOption(
              context,
              ref,
              ThemeMode.dark,
              currentThemeMode,
              themeNotifier,
              theme,
            ),
            const SizedBox(height: 16),
            _buildThemeOption(
              context,
              ref,
              ThemeMode.system,
              currentThemeMode,
              themeNotifier,
              theme,
            ),

            const SizedBox(height: 32),

            // Theme Preview
            _buildThemePreview(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    WidgetRef ref,
    ThemeMode themeMode,
    ThemeMode currentThemeMode,
    ThemeModeNotifier themeNotifier,
    ThemeData theme,
  ) {
    final isSelected = currentThemeMode == themeMode;
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => themeNotifier.setThemeMode(themeMode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.1)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                themeMode.icon,
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    themeMode.displayName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.textTheme.titleMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    themeMode.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),

            // Selection indicator
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemePreview(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preview',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.dividerColor,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Sample post
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: theme.colorScheme.primary,
                    child: Icon(
                      Icons.person,
                      color: theme.colorScheme.onPrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GamerFlick User',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '2 hours ago',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color
                                ?.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.more_vert,
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Just had an amazing gaming session! 🎮 The new update is incredible and the graphics are mind-blowing. Can\'t wait to share more highlights with you all!',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),

              // Sample image placeholder
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    Icons.image,
                    color: theme.colorScheme.primary,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Action buttons
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.favorite_border,
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.comment_outlined,
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.share_outlined,
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                    onPressed: () {},
                  ),
                  const Spacer(),
                  Text(
                    '42 likes',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Quick theme toggle widget for use in other screens
class ThemeToggleButton extends ConsumerWidget {
  final bool showLabel;
  final VoidCallback? onPressed;

  const ThemeToggleButton({
    super.key,
    this.showLabel = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentThemeMode = ref.watch(themeModeProvider);
    final themeNotifier = ref.read(themeModeProvider.notifier);

    return IconButton(
      icon: Icon(currentThemeMode.icon),
      onPressed: onPressed ?? () => themeNotifier.toggleTheme(),
      tooltip: showLabel ? 'Toggle theme' : null,
    );
  }
}

/// Theme mode selector for use in settings
class ThemeModeSelector extends ConsumerWidget {
  const ThemeModeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentThemeMode = ref.watch(themeModeProvider);
    final themeNotifier = ref.read(themeModeProvider.notifier);

    return ListTile(
      leading: Icon(
        currentThemeMode.icon,
        color: theme.colorScheme.primary,
      ),
      title: const Text('Theme'),
      subtitle: Text(currentThemeMode.displayName),
      trailing: DropdownButton<ThemeMode>(
        value: currentThemeMode,
        underline: const SizedBox(),
        items: ThemeMode.values.map((mode) {
          return DropdownMenuItem(
            value: mode,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(mode.icon, size: 16),
                const SizedBox(width: 8),
                Text(mode.displayName),
              ],
            ),
          );
        }).toList(),
        onChanged: (ThemeMode? newValue) {
          if (newValue != null) {
            themeNotifier.setThemeMode(newValue);
          }
        },
      ),
    );
  }
}
