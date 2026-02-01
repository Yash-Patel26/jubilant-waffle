import 'package:gamer_flick/models/core/profile.dart';
import 'package:gamer_flick/models/post/story.dart';

class UserWithStories {
  final Profile user;
  final List<Story> stories;

  UserWithStories({
    required this.user,
    required this.stories,
  });
}
