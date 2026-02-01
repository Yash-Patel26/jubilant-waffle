class AnalyticsEvent {
  final String name;
  final Map<String, dynamic> parameters;

  AnalyticsEvent({
    required this.name,
    this.parameters = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'parameters': parameters,
    };
  }
}
