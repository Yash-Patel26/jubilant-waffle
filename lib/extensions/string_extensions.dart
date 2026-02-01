extension StringExtensions on String {
  /// Capitalizes the first letter of the string
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Truncates string to a fixed length with ellipsis
  String truncate(int length) {
    if (this.length <= length) return this;
    return '${substring(0, length)}...';
  }

  /// Checks if string is a valid username (alphanumeric and underscores, 3-20 chars)
  bool isValidUsername() {
    return RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(this);
  }

  /// Formats big numbers (e.g., 1500 -> 1.5K)
  String formatScore() {
    final score = int.tryParse(this);
    if (score == null) return this;
    if (score >= 1000000) {
      return '${(score / 1000000).toStringAsFixed(1)}M';
    } else if (score >= 1000) {
      return '${(score / 1000).toStringAsFixed(1)}K';
    }
    return score.toString();
  }
}
