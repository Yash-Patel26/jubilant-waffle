import 'package:flutter/material.dart';

class ResponsiveUtils {
  static const double _mobileBreakpoint = 600;
  static const double _tabletBreakpoint = 900;
  static const double _desktopBreakpoint = 1200;

  /// Get screen width
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get screen height
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Check if screen is mobile
  static bool isMobile(BuildContext context) {
    return screenWidth(context) < _mobileBreakpoint;
  }

  /// Check if screen is tablet
  static bool isTablet(BuildContext context) {
    return screenWidth(context) >= _mobileBreakpoint &&
        screenWidth(context) < _tabletBreakpoint;
  }

  /// Check if screen is desktop
  static bool isDesktop(BuildContext context) {
    return screenWidth(context) >= _desktopBreakpoint;
  }

  /// Check if screen is large desktop
  static bool isLargeDesktop(BuildContext context) {
    return screenWidth(context) >= 1400;
  }

  /// Get responsive padding
  static EdgeInsets responsivePadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(16.0);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(24.0);
    } else {
      return const EdgeInsets.all(32.0);
    }
  }

  /// Get responsive horizontal padding
  static EdgeInsets responsiveHorizontalPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.symmetric(horizontal: 16.0);
    } else if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 24.0);
    } else {
      return const EdgeInsets.symmetric(horizontal: 32.0);
    }
  }

  /// Get responsive vertical padding
  static EdgeInsets responsiveVerticalPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.symmetric(vertical: 16.0);
    } else if (isTablet(context)) {
      return const EdgeInsets.symmetric(vertical: 24.0);
    } else {
      return const EdgeInsets.symmetric(vertical: 32.0);
    }
  }

  /// Get responsive spacing
  static double responsiveSpacing(BuildContext context) {
    if (isMobile(context)) {
      return 8.0;
    } else if (isTablet(context)) {
      return 12.0;
    } else {
      return 16.0;
    }
  }

  /// Get responsive font size
  static double responsiveFontSize(
    BuildContext context, {
    double mobile = 14.0,
    double tablet = 16.0,
    double desktop = 18.0,
  }) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet;
    } else {
      return desktop;
    }
  }

  /// Get responsive icon size
  static double responsiveIconSize(
    BuildContext context, {
    double mobile = 20.0,
    double tablet = 24.0,
    double desktop = 28.0,
  }) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet;
    } else {
      return desktop;
    }
  }

  /// Get responsive avatar radius
  static double responsiveAvatarRadius(
    BuildContext context, {
    double mobile = 20.0,
    double tablet = 24.0,
    double desktop = 28.0,
  }) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet;
    } else {
      return desktop;
    }
  }

  /// Get responsive card radius
  static double responsiveCardRadius(BuildContext context) {
    if (isMobile(context)) {
      return 8.0;
    } else if (isTablet(context)) {
      return 12.0;
    } else {
      return 16.0;
    }
  }

  /// Get responsive button height
  static double responsiveButtonHeight(BuildContext context) {
    if (isMobile(context)) {
      return 44.0;
    } else if (isTablet(context)) {
      return 48.0;
    } else {
      return 52.0;
    }
  }

  /// Get responsive input field height
  static double responsiveInputHeight(BuildContext context) {
    if (isMobile(context)) {
      return 48.0;
    } else if (isTablet(context)) {
      return 52.0;
    } else {
      return 56.0;
    }
  }

  /// Get responsive max width for content
  static double responsiveMaxWidth(BuildContext context) {
    if (isMobile(context)) {
      return double.infinity;
    } else if (isTablet(context)) {
      return 600;
    } else if (isDesktop(context)) {
      return 800;
    } else {
      return 1000;
    }
  }

  /// Get responsive grid cross axis count
  static int responsiveGridCrossAxisCount(
    BuildContext context, {
    int mobile = 1,
    int tablet = 2,
    int desktop = 3,
    int largeDesktop = 4,
  }) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet;
    } else if (isDesktop(context)) {
      return desktop;
    } else {
      return largeDesktop;
    }
  }

  /// Get responsive aspect ratio
  static double responsiveAspectRatio(
    BuildContext context, {
    double mobile = 16 / 9,
    double tablet = 4 / 3,
    double desktop = 3 / 2,
  }) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet;
    } else {
      return desktop;
    }
  }

  /// Get responsive sidebar width
  static double responsiveSidebarWidth(BuildContext context) {
    if (isMobile(context)) {
      return 0; // No sidebar on mobile
    } else if (isTablet(context)) {
      return 200;
    } else {
      return 250;
    }
  }

  /// Get responsive bottom navigation height
  static double responsiveBottomNavHeight(BuildContext context) {
    if (isMobile(context)) {
      return 60.0;
    } else {
      return 70.0;
    }
  }

  /// Get responsive app bar height
  static double responsiveAppBarHeight(BuildContext context) {
    if (isMobile(context)) {
      return 56.0;
    } else if (isTablet(context)) {
      return 64.0;
    } else {
      return 72.0;
    }
  }

  /// Get responsive drawer width
  static double responsiveDrawerWidth(BuildContext context) {
    if (isMobile(context)) {
      return screenWidth(context) * 0.8;
    } else if (isTablet(context)) {
      return 300;
    } else {
      return 350;
    }
  }

  /// Get responsive modal width
  static double responsiveModalWidth(BuildContext context) {
    if (isMobile(context)) {
      return screenWidth(context) * 0.9;
    } else if (isTablet(context)) {
      return 500;
    } else {
      return 600;
    }
  }

  /// Get responsive modal height
  static double responsiveModalHeight(BuildContext context) {
    if (isMobile(context)) {
      return screenHeight(context) * 0.7;
    } else if (isTablet(context)) {
      return 600;
    } else {
      return 700;
    }
  }

  /// Get responsive list item height
  static double responsiveListItemHeight(BuildContext context) {
    if (isMobile(context)) {
      return 60.0;
    } else if (isTablet(context)) {
      return 70.0;
    } else {
      return 80.0;
    }
  }

  /// Get responsive image size
  static double responsiveImageSize(
    BuildContext context, {
    double mobile = 100.0,
    double tablet = 120.0,
    double desktop = 140.0,
  }) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet;
    } else {
      return desktop;
    }
  }

  /// Get responsive thumbnail size
  static double responsiveThumbnailSize(BuildContext context) {
    if (isMobile(context)) {
      return 60.0;
    } else if (isTablet(context)) {
      return 80.0;
    } else {
      return 100.0;
    }
  }

  /// Get responsive story size
  static double responsiveStorySize(BuildContext context) {
    if (isMobile(context)) {
      return 70.0;
    } else if (isTablet(context)) {
      return 90.0;
    } else {
      return 110.0;
    }
  }

  /// Get responsive post card width
  static double responsivePostCardWidth(BuildContext context) {
    if (isMobile(context)) {
      return screenWidth(context) - 32;
    } else if (isTablet(context)) {
      return 500;
    } else {
      return 600;
    }
  }

  /// Get responsive tournament card width
  static double responsiveTournamentCardWidth(BuildContext context) {
    if (isMobile(context)) {
      return screenWidth(context) - 32;
    } else if (isTablet(context)) {
      return 400;
    } else {
      return 450;
    }
  }

  /// Get responsive community card width
  static double responsiveCommunityCardWidth(BuildContext context) {
    if (isMobile(context)) {
      return screenWidth(context) - 32;
    } else if (isTablet(context)) {
      return 350;
    } else {
      return 400;
    }
  }

  /// Get responsive chat bubble max width
  static double responsiveChatBubbleMaxWidth(BuildContext context) {
    if (isMobile(context)) {
      return screenWidth(context) * 0.75;
    } else if (isTablet(context)) {
      return 400;
    } else {
      return 500;
    }
  }

  /// Get responsive video player height
  static double responsiveVideoPlayerHeight(BuildContext context) {
    if (isMobile(context)) {
      return 200;
    } else if (isTablet(context)) {
      return 300;
    } else {
      return 400;
    }
  }



  /// Get responsive notification item height
  static double responsiveNotificationItemHeight(BuildContext context) {
    if (isMobile(context)) {
      return 80.0;
    } else if (isTablet(context)) {
      return 90.0;
    } else {
      return 100.0;
    }
  }

  /// Get responsive search bar height
  static double responsiveSearchBarHeight(BuildContext context) {
    if (isMobile(context)) {
      return 44.0;
    } else if (isTablet(context)) {
      return 48.0;
    } else {
      return 52.0;
    }
  }

  /// Get responsive filter chip height
  static double responsiveFilterChipHeight(BuildContext context) {
    if (isMobile(context)) {
      return 32.0;
    } else if (isTablet(context)) {
      return 36.0;
    } else {
      return 40.0;
    }
  }

  /// Get responsive tab bar height
  static double responsiveTabBarHeight(BuildContext context) {
    if (isMobile(context)) {
      return 48.0;
    } else if (isTablet(context)) {
      return 52.0;
    } else {
      return 56.0;
    }
  }

  /// Get responsive floating action button size
  static double responsiveFABSize(BuildContext context) {
    if (isMobile(context)) {
      return 56.0;
    } else if (isTablet(context)) {
      return 64.0;
    } else {
      return 72.0;
    }
  }

  /// Get responsive snackbar duration
  static Duration responsiveSnackBarDuration(BuildContext context) {
    if (isMobile(context)) {
      return const Duration(seconds: 3);
    } else {
      return const Duration(seconds: 4);
    }
  }

  /// Get responsive animation duration
  static Duration responsiveAnimationDuration(BuildContext context) {
    if (isMobile(context)) {
      return const Duration(milliseconds: 300);
    } else {
      return const Duration(milliseconds: 400);
    }
  }

  /// Get responsive page transition duration
  static Duration responsivePageTransitionDuration(BuildContext context) {
    if (isMobile(context)) {
      return const Duration(milliseconds: 250);
    } else {
      return const Duration(milliseconds: 350);
    }
  }
}
