import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';

/// Wrap any screen content with this to get consistent, mobile-safe padding
/// and a centered, constrained width on larger screens.
class ResponsivePage extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const ResponsivePage({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    final horizontalPadding =
        padding ?? ResponsiveUtils.responsiveHorizontalPadding(context);
    final maxWidth = ResponsiveUtils.responsiveMaxWidth(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: horizontalPadding,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
