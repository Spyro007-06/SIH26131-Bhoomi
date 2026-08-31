/// Timeline and farm case file wire models matching API_CONTRACT §11.

class TimelineEventModel {
  final String id;
  final String type; // diagnosis | observation | treatment | alert | follow_up | confirmation
  final String title;
  final String? description;
  final String timestamp;
  final Map<String, dynamic>? metadata;
  final String? problemId;
  final String? severity;

  String get eventType => type;

  const TimelineEventModel({
    required this.id,
    String? type,
    String? eventType,
    required this.title,
    this.description,
    required this.timestamp,
    this.metadata,
    String? farmId,
    this.problemId,
    this.severity,
  }) : type = type ?? eventType ?? 'event';

  factory TimelineEventModel.fromJson(Map<String, dynamic> json) {
    return TimelineEventModel(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? json['event_type'] as String? ?? 'event',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      timestamp: json['timestamp'] as String? ?? json['created_at'] as String? ?? '',
      metadata: json['metadata'] as Map<String, dynamic>?,
      problemId: json['problem_id'] as String?,
      severity: json['severity'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        if (description != null) 'description': description,
        'timestamp': timestamp,
        if (metadata != null) 'metadata': metadata,
        if (problemId != null) 'problem_id': problemId,
        if (severity != null) 'severity': severity,
      };
}

class TimelineResponse {
  final List<TimelineEventModel> events;
  final String? nextCursor;
  int get count => events.length;

  const TimelineResponse({
    required this.events,
    this.nextCursor,
    int? count,
  });

  factory TimelineResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['events'] as List<dynamic>?)
            ?.map((e) => TimelineEventModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        (json['timeline'] as List<dynamic>?)
            ?.map((e) => TimelineEventModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return TimelineResponse(
      events: list,
      nextCursor: json['next_cursor'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'events': events.map((e) => e.toJson()).toList(),
        if (nextCursor != null) 'next_cursor': nextCursor,
      };
}
