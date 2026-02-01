class Game {
  final String id;
  final String name;
  final String? description;
  final String? genre;
  final List<String>? platforms;
  final String? imageUrl;
  final DateTime? releaseDate;
  final int? popularityScore;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool? isActive;

  Game({
    required this.id,
    required this.name,
    this.description,
    this.genre,
    this.platforms,
    this.imageUrl,
    this.releaseDate,
    this.popularityScore,
    this.createdAt,
    this.updatedAt,
    this.isActive,
  });

  factory Game.fromMap(Map<String, dynamic> map) {
    return Game(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      genre: map['genre'] as String?,
      platforms: map['platforms'] != null 
          ? List<String>.from(map['platforms'])
          : null,
      imageUrl: map['image_url'] as String?,
      releaseDate: map['release_date'] != null
          ? DateTime.parse(map['release_date'] as String)
          : null,
      popularityScore: map['popularity_score'] as int?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      isActive: map['is_active'] as bool? ?? true,
    );
  }

  factory Game.fromJson(Map<String, dynamic> json) => Game.fromMap(json);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'genre': genre,
      'platforms': platforms,
      'image_url': imageUrl,
      'release_date': releaseDate?.toIso8601String(),
      'popularity_score': popularityScore,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_active': isActive,
    };
  }

  Map<String, dynamic> toJson() => toMap();
}
