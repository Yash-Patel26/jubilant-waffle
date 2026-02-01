enum SearchResultType {
  user,
  post,
  game,
  community,
  tournament,
  reel,
}

class SearchResult {
  final String id;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final SearchResultType type;
  final dynamic originalObject;

  SearchResult({
    required this.id,
    required this.title,
    this.subtitle,
    this.imageUrl,
    required this.type,
    required this.originalObject,
  });
}
