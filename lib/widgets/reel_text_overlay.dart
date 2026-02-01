import 'package:flutter/material.dart';

class ReelTextOverlay extends StatelessWidget {
  final List<TextOverlayItem> textOverlays;
  final bool isVisible;

  const ReelTextOverlay({
    super.key,
    required this.textOverlays,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible || textOverlays.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: Stack(
        children: textOverlays.map((overlay) {
          return Positioned(
            top: overlay.top,
            left: overlay.left,
            right: overlay.right,
            bottom: overlay.bottom,
            child: Container(
              padding: overlay.padding,
              decoration: overlay.decoration,
              child: Text(
                overlay.text,
                style: overlay.textStyle,
                textAlign: overlay.textAlign,
                maxLines: overlay.maxLines,
                overflow: overlay.overflow,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class TextOverlayItem {
  final String text;
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final EdgeInsets padding;
  final BoxDecoration? decoration;
  final TextStyle textStyle;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow overflow;

  const TextOverlayItem({
    required this.text,
    this.top,
    this.left,
    this.right,
    this.bottom,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.decoration,
    this.textStyle = const TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.w500,
      shadows: [
        Shadow(
          blurRadius: 2,
          color: Colors.black,
        ),
      ],
    ),
    this.textAlign = TextAlign.center,
    this.maxLines,
    this.overflow = TextOverflow.ellipsis,
  });
}

// Predefined text overlay styles for common use cases
class ReelTextOverlayStyles {
  static const TextStyle pinkTextStyle = TextStyle(
    color: Color(0xFFE91E63), // Pink color
    fontSize: 18,
    fontWeight: FontWeight.bold,
    shadows: [
      Shadow(
        blurRadius: 2,
        color: Colors.black,
      ),
    ],
  );

  static const TextStyle whiteTextStyle = TextStyle(
    color: Colors.white,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    shadows: [
      Shadow(
        blurRadius: 2,
        color: Colors.black,
      ),
    ],
  );

  static const TextStyle watermarkStyle = TextStyle(
    color: Colors.white,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    shadows: [
      Shadow(
        blurRadius: 1,
        color: Colors.black,
      ),
    ],
  );

  // Example overlay items for the Instagram-style reel shown in the image
  static List<TextOverlayItem> get exampleOverlays => [
        // Top pink text block
        TextOverlayItem(
          text: "SSC ke Exams dene ki jab\nMeri bari ayi to ye sb hone Iga",
          top: 100,
          left: 20,
          right: 20,
          textStyle: pinkTextStyle,
          textAlign: TextAlign.center,
          maxLines: 2,
        ),
        // Middle watermark
        TextOverlayItem(
          text: "@sarkarinaukriwla",
          top: 200,
          left: 20,
          textStyle: watermarkStyle,
          textAlign: TextAlign.left,
        ),
        // Bottom white text in parentheses
        TextOverlayItem(
          text: "(Meri kismt m hi hona h ye sb)",
          top: null,
          bottom: 200,
          left: 20,
          right: 20,
          textStyle: whiteTextStyle,
          textAlign: TextAlign.center,
        ),
      ];
}
