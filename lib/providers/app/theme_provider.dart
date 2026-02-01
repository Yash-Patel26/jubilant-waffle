import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamer_flick/repositories/storage/local_storage_repository.dart';

/// Provides the current theme mode (dark only) and allows toggling.
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final storageRepo = ref.watch(localStorageRepositoryProvider);
  return ThemeModeNotifier(storageRepo);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final ILocalStorageRepository _storageRepo;

  ThemeModeNotifier(this._storageRepo) : super(ThemeMode.dark) {
    _loadThemeMode();
  }

  /// Load the saved theme mode from storage
  Future<void> _loadThemeMode() async {
    try {
      final savedMode = _storageRepo.getString('theme_mode');
      if (savedMode != null) {
        switch (savedMode) {
          case 'dark':
            state = ThemeMode.dark;
            break;
          case 'light':
          case 'system':
          default:
            // Force dark mode for all other cases
            state = ThemeMode.dark;
            await _storageRepo.setString('theme_mode', 'dark');
            break;
        }
      } else {
        // If no saved mode, default to dark and save it
        state = ThemeMode.dark;
        await _storageRepo.setString('theme_mode', 'dark');
      }
    } catch (e) {
      // If there's an error loading, default to dark theme
      state = ThemeMode.dark;
    }
  }

  /// Set the theme mode and save to storage (only dark mode allowed)
  Future<void> setThemeMode(ThemeMode mode) async {
    // Force dark mode regardless of input
    state = ThemeMode.dark;
    try {
      await _storageRepo.setString('theme_mode', 'dark');
    } catch (e) {
      // If saving fails, the theme will still be applied for this session
      print('Failed to save theme mode: $e');
    }
  }

  /// Toggle theme (always sets to dark mode)
  Future<void> toggleTheme() async {
    await setThemeMode(ThemeMode.dark);
  }

  /// Get the current theme mode as a string for display
  String get themeModeString {
    return 'Dark';
  }

  /// Get the icon for the current theme mode
  IconData get themeModeIcon {
    return Icons.dark_mode;
  }

  /// Check if the current theme is dark (always true)
  bool isDarkMode(BuildContext context) {
    return true;
  }
}

/// Provider for checking if dark mode is active (always true)
final isDarkModeProvider = Provider<bool>((ref) {
  return true;
});

/// Extension methods for easier theme mode handling
extension ThemeModeExtension on ThemeMode {
  String get displayName {
    return 'Dark';
  }

  IconData get icon {
    return Icons.dark_mode;
  }

  String get description {
    return 'Dark theme only';
  }
}
