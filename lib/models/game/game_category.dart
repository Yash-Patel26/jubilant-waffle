class GameCategory {
  final String id;
  final String name;
  final String imageUrl;

  GameCategory({
    required this.id,
    required this.name,
    required this.imageUrl,
  });

  factory GameCategory.fromJson(Map<String, dynamic> json) {
    return GameCategory(
      id: json['id'],
      name: json['name'],
      imageUrl: json['image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image_url': imageUrl,
    };
  }
}
