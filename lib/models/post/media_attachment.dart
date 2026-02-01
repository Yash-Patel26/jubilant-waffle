class MediaAttachment {
  final String id;
  final String url;
  final String type; // 'image', 'video', etc.
  final String? thumbnailUrl;

  MediaAttachment({
    required this.id,
    required this.url,
    required this.type,
    this.thumbnailUrl,
  });

  factory MediaAttachment.fromJson(Map<String, dynamic> json) {
    return MediaAttachment(
      id: json['id'] as String,
      url: json['url'] as String,
      type: json['type'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'type': type,
      'thumbnailUrl': thumbnailUrl,
    };
  }
}
