import 'package:flutter/material.dart';
import '../widgets/facebook_story_creator.dart';

class StoryCreatorHelper {
  /// Shows the Facebook-style story creator modal
  static void showStoryCreator(
    BuildContext context, {
    required Function(Map<String, dynamic>) onStoryCreated,
    VoidCallback? onClose,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FacebookStoryCreator(
        onStoryCreated: onStoryCreated,
        onClose: onClose,
      ),
    );
  }

  /// Shows the story creator with a custom callback for story creation
  static void showStoryCreatorWithCallback(
    BuildContext context, {
    required Function(Map<String, dynamic>) onStoryCreated,
    VoidCallback? onClose,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FacebookStoryCreator(
        onStoryCreated: onStoryCreated,
        onClose: onClose,
      ),
    );
  }
}
