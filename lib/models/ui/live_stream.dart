class LiveStream {
  final String id;
  final String streamerId;
  final String title;
  final String? description;
  final String streamUrl;
  final DateTime startTime;
  final DateTime? endTime;
  final int viewerCount;

  LiveStream({
    required this.id,
    required this.streamerId,
    required this.title,
    this.description,
    required this.streamUrl,
    required this.startTime,
    this.endTime,
    required this.viewerCount,
  });

  factory LiveStream.fromJson(Map<String, dynamic> json) {
    return LiveStream(
      id: json['id'],
      streamerId: json['streamer_id'],
      title: json['title'],
      description: json['description'],
      streamUrl: json['stream_url'],
      startTime: DateTime.parse(json['start_time']),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      viewerCount: json['viewer_count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'streamer_id': streamerId,
      'title': title,
      'description': description,
      'stream_url': streamUrl,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'viewer_count': viewerCount,
    };
  }
}
