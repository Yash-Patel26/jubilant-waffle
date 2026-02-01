import 'package:flutter/material.dart';
import '../widgets/facebook_post_creator.dart';

class PostCreatorHelper {
  /// Shows the Facebook-style post creator modal
  static void showPostCreator(BuildContext context, {
    required Function(Map<String, dynamic>) onPostCreated,
    VoidCallback? onClose,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FacebookPostCreator(
        onPostCreated: onPostCreated,
        onClose: onClose,
      ),
    );
  }

  /// Shows the post creator with a custom callback for post creation
  static void showPostCreatorWithCallback(
    BuildContext context, {
    required Function(Map<String, dynamic>) onPostCreated,
    VoidCallback? onClose,
    String? initialText,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FacebookPostCreator(
        onPostCreated: onPostCreated,
        onClose: onClose,
      ),
    );
  }
}
