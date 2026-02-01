import 'package:flutter/material.dart';

class FeatureHighlight {
  final String title;
  final String description;
  final IconData icon;

  FeatureHighlight({
    required this.title,
    required this.description,
    required this.icon,
  });

  factory FeatureHighlight.fromJson(Map<String, dynamic> json) {
    return FeatureHighlight(
      title: json['title'],
      description: json['description'],
      icon: IconData(json['icon_code_point'], fontFamily: json['icon_font_family']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'icon_code_point': icon.codePoint,
      'icon_font_family': icon.fontFamily,
    };
  }
}
