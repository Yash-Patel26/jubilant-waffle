import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, kIsWeb;
import 'package:flutter/services.dart';

class AppTheme {
  // --- Enhanced Eye-Friendly Dark Theme Color Palette ---
  // Softer, more comfortable colors for dark mode with better contrast
  static const Color _primaryColor = Color(0xFF64B5F6); // Soft blue
  static const Color _primaryVariantColor =
      Color(0xFF42A5F5); // Darker blue variant
  static const Color _secondaryColor = Color(0xFFF48FB1); // Soft pink
  static const Color _secondaryVariantColor =
      Color(0xFFF06292); // Darker pink variant

  // Background colors with subtle variations
  static const Color _backgroundColor = Color(0xFF0A0A0A); // Deepest dark
  static const Color _surfaceColor = Color(0xFF121212); // Surface dark
  static const Color _cardColor = Color(0xFF1E1E1E); // Card background

  // Text colors with better hierarchy
  static const Color _textColor =
      Color(0xFFFAFAFA); // Primary text (almost white)
  static const Color _textSecondaryColor = Color(0xFFBDBDBD); // Secondary text
  static const Color _textTertiaryColor = Color(0xFF9E9E9E); // Tertiary text
  static const Color _textDisabledColor = Color(0xFF757575); // Disabled text

  // Border and divider colors
  static const Color _borderColor = Color(0xFF2C2C2C); // Subtle border
  static const Color _borderFocusedColor = Color(0xFF64B5F6); // Focused border
  static const Color _dividerColor = Color(0xFF424242); // Divider color

  // Semantic colors
  static const Color _errorColor = Color(0xFFEF5350); // Material Design error
  static const Color _errorVariantColor = Color(0xFFE53935); // Darker error
  static const Color _successColor =
      Color(0xFF66BB6A); // Material Design success
  static const Color _warningColor =
      Color(0xFFFFB74D); // Material Design warning
  static const Color _infoColor = Color(0xFF81C784); // Material Design info

  // Accent colors for gaming elements
  static const Color _accentPurple = Color(0xFFBA68C8); // Purple accent
  static const Color _accentIndigo = Color(0xFF7986CB); // Indigo accent

  static bool get isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: _primaryColor,
      primaryColorDark: _primaryVariantColor,
      primaryColorLight: _primaryColor,
      scaffoldBackgroundColor: _backgroundColor,
      canvasColor: _surfaceColor,
      cardColor: _cardColor,
      dividerColor: _dividerColor,
      focusColor: _borderFocusedColor,
      unselectedWidgetColor: _textTertiaryColor,
      disabledColor: _textDisabledColor,
      fontFamily: isIOS ? null : 'Roboto',
      // Ensure emoji/symbol coverage across platforms without bundling heavy fonts
      fontFamilyFallback: const <String>[
        'Noto Color Emoji',
        'Segoe UI Emoji',
        'Apple Color Emoji',
        'EmojiOne Color',
        'Twemoji Mozilla',
      ],

      colorScheme: const ColorScheme.dark(
        primary: _primaryColor,
        primaryContainer: _primaryVariantColor,
        secondary: _secondaryColor,
        secondaryContainer: _secondaryVariantColor,
        surface: _surfaceColor,
        surfaceContainerHighest: _cardColor,
        error: _errorColor,
        errorContainer: _errorVariantColor,
        onPrimary: Colors.black,
        onPrimaryContainer: Colors.black,
        onSecondary: Colors.black,
        onSecondaryContainer: Colors.black,
        onSurface: _textColor,
        onSurfaceVariant: _textSecondaryColor,
        onError: Colors.black,
        onErrorContainer: Colors.black,
        outline: _borderColor,
        outlineVariant: _dividerColor,
        brightness: Brightness.dark,
        // Additional semantic colors
        tertiary: _accentPurple,
        tertiaryContainer: _accentIndigo,
        onTertiary: Colors.black,
        onTertiaryContainer: Colors.black,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: _backgroundColor, // Dark background for AppBar
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: isIOS ? null : 'Roboto',
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: _textColor, // Use soft white instead of bright blue
          letterSpacing: 1.2,
        ),
        iconTheme: const IconThemeData(color: _textColor), // Soft white icons
        actionsIconTheme:
            const IconThemeData(color: _textSecondaryColor), // Muted grey
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),

      cardTheme: CardThemeData(
        color: _cardColor.withValues(alpha: 0.95),
        elevation: 4, // Reduced elevation for softer look
        shadowColor: Colors.black.withValues(alpha: 0.1), // Softer shadow
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: _borderColor, width: 0.5), // Subtle border
        ),
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white, // White text on blue button
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
          textStyle: TextStyle(
            fontFamily: isIOS ? null : 'Roboto',
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
          elevation: 2, // Reduced elevation
          shadowColor: Colors.black.withValues(alpha: 0.1), // Softer shadow
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primaryColor,
          textStyle: TextStyle(
            fontFamily: isIOS ? null : 'Roboto',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryColor,
          side: const BorderSide(color: _primaryColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
          textStyle: TextStyle(
            fontFamily: isIOS ? null : 'Roboto',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        extendedPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        extendedTextStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _surfaceColor,
        selectedItemColor: _primaryColor,
        unselectedItemColor: _textSecondaryColor,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _surfaceColor,
        indicatorColor: _primaryColor.withValues(alpha: 0.1),
        labelTextStyle: WidgetStateProperty.all(
          TextStyle(
            color: _textColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: _primaryColor);
          }
          return IconThemeData(color: _textSecondaryColor);
        }),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: _cardColor,
        contentTextStyle: const TextStyle(
          color: _textColor,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 8,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: _cardColor,
        surfaceTintColor: _cardColor,
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: TextStyle(
          color: _textColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: TextStyle(
          color: _textSecondaryColor,
          fontSize: 14,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: _cardColor,
        surfaceTintColor: _cardColor,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: TextStyle(
          color: _textColor,
          fontSize: 14,
        ),
      ),

      listTileTheme: ListTileThemeData(
        tileColor: _cardColor,
        selectedTileColor: _primaryColor.withValues(alpha: 0.1),
        textColor: _textColor,
        iconColor: _textSecondaryColor,
        selectedColor: _primaryColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minVerticalPadding: 8,
        titleTextStyle: TextStyle(
          color: _textColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: TextStyle(
          color: _textSecondaryColor,
          fontSize: 14,
        ),
      ),

      expansionTileTheme: ExpansionTileThemeData(
        backgroundColor: _cardColor,
        collapsedBackgroundColor: _surfaceColor,
        textColor: _textColor,
        iconColor: _primaryColor,
        collapsedTextColor: _textSecondaryColor,
        collapsedIconColor: _textSecondaryColor,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _cardColor.withValues(alpha: 0.85),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: _borderColor, width: 1), // Softer border
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: _borderColor), // Use consistent border color
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: _primaryColor, width: 1.5), // Reduced width
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _errorColor, width: 1.5),
        ),
        labelStyle: TextStyle(
          fontFamily: isIOS ? null : 'Roboto',
          color: _textSecondaryColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(
          fontFamily: isIOS ? null : 'Roboto',
          color: _textSecondaryColor.withValues(alpha: 0.7),
          fontSize: 14,
        ),
        errorStyle: TextStyle(
          color: _errorColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        helperStyle: TextStyle(
          color: _textTertiaryColor,
          fontSize: 12,
        ),
        prefixIconColor: _textSecondaryColor,
        suffixIconColor: _textSecondaryColor,
      ),

      textTheme: ThemeData.dark()
          .textTheme
          .apply(
            fontFamily: isIOS ? null : 'Roboto',
            bodyColor: _textColor,
            displayColor: _textColor,
          )
          .copyWith(
            displayLarge: TextStyle(
              fontSize: 57,
              fontWeight: FontWeight.w400,
              color: _textColor,
              letterSpacing: -0.25,
            ),
            displayMedium: TextStyle(
              fontSize: 45,
              fontWeight: FontWeight.w400,
              color: _textColor,
              letterSpacing: 0,
            ),
            displaySmall: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w400,
              color: _textColor,
              letterSpacing: 0,
            ),
            headlineLarge: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w600,
              color: _textColor,
              letterSpacing: 0,
            ),
            headlineMedium: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: _textColor,
            ),
            headlineSmall: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: _textColor,
            ),
            titleLarge: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: _textColor,
            ),
            titleMedium: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: _textColor,
            ),
            titleSmall: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: _textSecondaryColor,
            ),
            bodyLarge: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: _textColor,
            ),
            bodyMedium: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: _textColor,
            ),
            bodySmall: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.normal,
              color: _textSecondaryColor,
            ),
            labelLarge: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _textColor,
            ),
            labelMedium: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _textSecondaryColor,
            ),
            labelSmall: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _textSecondaryColor,
            ),
          ),

      iconTheme: const IconThemeData(
        color: _textColor,
        size: 24,
      ),

      dividerTheme: const DividerThemeData(
        color: _dividerColor,
        thickness: 1,
        space: 1,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: _cardColor,
        selectedColor: _primaryColor,
        disabledColor: _cardColor.withValues(alpha: 0.5),
        labelStyle: const TextStyle(color: _textColor),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _primaryColor;
          }
          return _textSecondaryColor;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _primaryColor.withValues(alpha: 0.5);
          }
          return _cardColor;
        }),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _primaryColor;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: const BorderSide(color: _borderColor, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _primaryColor;
          }
          return _textSecondaryColor;
        }),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: _primaryColor,
        inactiveTrackColor: _cardColor,
        thumbColor: _primaryColor,
        overlayColor: _primaryColor.withValues(alpha: 0.2),
        valueIndicatorColor: _primaryColor,
        valueIndicatorTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: _primaryColor,
        linearTrackColor: _cardColor,
        circularTrackColor: _cardColor,
      ),

      splashFactory: InkRipple.splashFactory, // Modern ripple effect
      highlightColor: _primaryColor.withValues(alpha: 0.05), // Softer highlight
      splashColor: _primaryColor.withValues(alpha: 0.1), // Softer splash
      hoverColor: _primaryColor.withValues(alpha: 0.05), // Softer hover
    );
  }

  // ============================================
  // STATIC COLOR GETTERS - Use these throughout the app
  // ============================================

  // Primary & Secondary Colors
  static Color get primaryColor => _primaryColor;
  static Color get primaryVariantColor => _primaryVariantColor;
  static Color get secondaryColor => _secondaryColor;
  static Color get secondaryVariantColor => _secondaryVariantColor;

  // Background Colors
  static Color get backgroundColor => _backgroundColor;
  static Color get surfaceColor => _surfaceColor;
  static Color get cardColor => _cardColor;

  // Text Colors
  static Color get textColor => _textColor;
  static Color get textPrimaryColor => _textColor;
  static Color get textSecondaryColor => _textSecondaryColor;
  static Color get textTertiaryColor => _textTertiaryColor;
  static Color get textDisabledColor => _textDisabledColor;
  static Color get textHintColor => _textSecondaryColor.withOpacity(0.7);

  // Border & Divider Colors
  static Color get borderColor => _borderColor;
  static Color get borderFocusedColor => _borderFocusedColor;
  static Color get dividerColor => _dividerColor;

  // Semantic Colors
  static Color get errorColor => _errorColor;
  static Color get errorVariantColor => _errorVariantColor;
  static Color get successColor => _successColor;
  static Color get warningColor => _warningColor;
  static Color get infoColor => _infoColor;

  // Accent Colors
  static Color get accentPurple => _accentPurple;
  static Color get accentIndigo => _accentIndigo;

  // ============================================
  // OPACITY VARIANTS - For consistent transparency
  // ============================================

  // Overlay colors
  static Color get overlayLight => Colors.white.withOpacity(0.1);
  static Color get overlayMedium => Colors.white.withOpacity(0.2);
  static Color get overlayDark => Colors.black.withOpacity(0.3);
  static Color get overlayHeavy => Colors.black.withOpacity(0.6);

  // Shimmer/Placeholder colors
  static Color get shimmerBase => _cardColor;
  static Color get shimmerHighlight => _surfaceColor.withOpacity(0.5);
  static Color get placeholderColor => _textTertiaryColor.withOpacity(0.3);

  // Interactive state colors
  static Color get hoverColor => _primaryColor.withOpacity(0.05);
  static Color get pressedColor => _primaryColor.withOpacity(0.1);
  static Color get focusColor => _primaryColor.withOpacity(0.15);
  static Color get selectedColor => _primaryColor.withOpacity(0.2);
  static Color get disabledBackgroundColor => _cardColor.withOpacity(0.5);

  // Shadow colors
  static Color get shadowColor => Colors.black.withOpacity(0.1);
  static Color get shadowColorDark => Colors.black.withOpacity(0.2);
  static Color get shadowColorLight => Colors.black.withOpacity(0.05);

  // ============================================
  // SPECIFIC UI ELEMENT COLORS
  // ============================================

  // Icon colors
  static Color get iconColor => _textColor;
  static Color get iconSecondaryColor => _textSecondaryColor;
  static Color get iconDisabledColor => _textDisabledColor;
  static Color get iconActiveColor => _primaryColor;

  // Like/Action colors
  static Color get likeColor => const Color(0xFFE53935); // Red for likes
  static Color get saveColor => _primaryColor; // Blue for saves
  static Color get shareColor => _textSecondaryColor;
  static Color get commentColor => _textSecondaryColor;

  // Notification type colors
  static Color get notificationComment => _successColor;
  static Color get notificationLike => likeColor;
  static Color get notificationFollow => _primaryColor;
  static Color get notificationMessage => _accentPurple;
  static Color get notificationTournament => _warningColor;
  static Color get notificationDefault => _textSecondaryColor;

  // Online/Status colors
  static Color get onlineColor => _successColor;
  static Color get offlineColor => _textDisabledColor;
  static Color get awayColor => _warningColor;
  static Color get busyColor => _errorColor;

  // Progress colors
  static Color get progressBackground => _cardColor;
  static Color get progressForeground => _primaryColor;
  static Color get progressBuffered => _textTertiaryColor;

  // Badge colors
  static Color get badgeColor => _errorColor;
  static Color get badgeTextColor => Colors.white;

  // ============================================
  // GAMING SPECIFIC COLORS
  // ============================================

  // Gaming gradient colors
  static List<Color> get gamingGradient => const [
    Color(0xFF0A0A0A),
    Color(0xFF1A1A2E),
    Color(0xFF16213E),
    Color(0xFF0F3460),
    Color(0xFF533483),
  ];

  // Glow effect colors
  static Color get glowCyan => const Color(0xFF00BCD4);
  static Color get glowPurple => const Color(0xFF9C27B0);
  static Color get glowPink => const Color(0xFFE91E63);
  static Color get glowOrange => const Color(0xFFFF9800);

  // Rank colors (for leaderboards)
  static Color get rankGold => const Color(0xFFFFD700);
  static Color get rankSilver => const Color(0xFFC0C0C0);
  static Color get rankBronze => const Color(0xFFCD7F32);
  static Color get rankDefault => _textSecondaryColor;

  // Tournament status colors
  static Color get tournamentDraft => _textTertiaryColor;
  static Color get tournamentRegistration => _primaryColor;
  static Color get tournamentInProgress => _successColor;
  static Color get tournamentCompleted => _accentPurple;
  static Color get tournamentCancelled => _errorColor;

  // ============================================
  // GRADIENT HELPERS
  // ============================================

  static LinearGradient get primaryGradient => LinearGradient(
    colors: [_primaryColor, _accentPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get secondaryGradient => LinearGradient(
    colors: [_secondaryColor, _secondaryVariantColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get surfaceGradient => LinearGradient(
    colors: [_surfaceColor, _cardColor],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static RadialGradient glowGradient(Color color, {double opacity = 0.3}) =>
    RadialGradient(
      colors: [color.withOpacity(opacity), Colors.transparent],
    );

  // ============================================
  // TEXT STYLE HELPERS
  // ============================================

  static TextStyle get captionStyle => TextStyle(
    color: _textTertiaryColor,
    fontSize: 12,
  );

  static TextStyle get timestampStyle => TextStyle(
    color: _textTertiaryColor,
    fontSize: 10,
  );

  static TextStyle get labelStyle => TextStyle(
    color: _textSecondaryColor,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static TextStyle get subtitleStyle => TextStyle(
    color: _textSecondaryColor,
    fontSize: 14,
  );

  // ============================================
  // BOX DECORATION HELPERS
  // ============================================

  static BoxDecoration get cardDecoration => BoxDecoration(
    color: _cardColor,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: _borderColor, width: 0.5),
  );

  static BoxDecoration get surfaceDecoration => BoxDecoration(
    color: _surfaceColor,
    borderRadius: BorderRadius.circular(12),
  );

  static BoxDecoration glowDecoration({
    Color? glowColor,
    double blurRadius = 15,
    double spreadRadius = 2,
  }) => BoxDecoration(
    color: _surfaceColor,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: (glowColor ?? _primaryColor).withOpacity(0.2),
        blurRadius: blurRadius,
        spreadRadius: spreadRadius,
      ),
    ],
  );
}
