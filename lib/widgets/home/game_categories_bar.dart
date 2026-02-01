import 'package:flutter/material.dart';

class GameCategoriesBar extends StatelessWidget {
  final List<String> categories;
  final String? selectedCategory;
  final Function(String) onCategorySelected;

  const GameCategoriesBar({
    super.key,
    required this.categories,
    this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final categoryColors = {
      'FPS': const Color(0xFFFF5722),
      'MOBA': const Color(0xFF2196F3),
      'RPG': const Color(0xFF9C27B0),
      'Racing': const Color(0xFF4CAF50),
      'Sports': const Color(0xFFFF9800),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: categories
              .map((category) => Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: _buildGameTag(
                      category,
                      categoryColors[category] ?? const Color(0xFF757575),
                      selectedCategory == category,
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildGameTag(String text, Color color, bool isSelected) {
    return GestureDetector(
      onTap: () => onCategorySelected(text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: Colors.white, width: 1) : null,
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
