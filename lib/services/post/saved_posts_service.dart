import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:gamer_flick/models/post/post.dart'; // No Post model, use Map<String, dynamic>

class SavedPostsService {
  final supabase = Supabase.instance.client;

  // Save a post
  Future<void> savePost(String postId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');
    await supabase.from('saved_posts').upsert({
      'user_id': userId,
      'post_id': postId,
    });
  }

  // Unsave a post
  Future<void> unsavePost(String postId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');
    await supabase
        .from('saved_posts')
        .delete()
        .eq('user_id', userId)
        .eq('post_id', postId);
  }

  // Check if a post is saved
  Future<bool> isPostSaved(String postId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return false;
    final res = await supabase
        .from('saved_posts')
        .select('id')
        .eq('user_id', userId)
        .eq('post_id', postId)
        .maybeSingle();
    return res != null;
  }

  // Get all saved posts for the current user
  Future<List<Map<String, dynamic>>> getSavedPosts() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];
    final savedRows = await supabase
        .from('saved_posts')
        .select('post_id')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    if ((savedRows as List).isEmpty) return [];
    final postIds = (savedRows).map((row) => row['post_id']).toList();
    if (postIds.isEmpty) return [];
    final posts = await supabase.from('posts').select().inFilter('id', postIds);
    return List<Map<String, dynamic>>.from(posts);
  }
}
