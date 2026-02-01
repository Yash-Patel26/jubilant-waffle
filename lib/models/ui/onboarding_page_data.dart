import 'package:flutter/material.dart';

class OnboardingPageData {
  final String title;
  final String subtitle;
  final String description;
  final String animationAsset;
  final Color backgroundColor;
  final Color accentColor;
  final Color textColor;

  OnboardingPageData({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.animationAsset,
    required this.backgroundColor,
    required this.accentColor,
    required this.textColor,
  });
}
