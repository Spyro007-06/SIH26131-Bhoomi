import 'farm_models.dart';

/// Closed-loop follow-up models matching API_CONTRACT §11.

typedef FollowUpItemModel = FollowUpModel;

class FollowUpModel {
  final String id;
  final String problemId;
  final String dueAt;
  final String? response; // improved | no_change | got_worse
  final String? imageAssetId;
  final String? respondedAt;
  final String? farmId;
  final String? target;
  final String? question;

  const FollowUpModel({
    required this.id,
    required this.problemId,
    required this.dueAt,
    this.response,
    this.imageAssetId,
    this.respondedAt,
    this.farmId,
    this.target,
    this.question,
  });

  factory FollowUpModel.fromJson(Map<String, dynamic> json) {
    return FollowUpModel(
      id: json['id'] as String,
      problemId: json['problem_id'] as String,
      dueAt: json['due_at'] as String,
      response: json['response'] as String?,
      imageAssetId: json['image_asset_id'] as String?,
      respondedAt: json['responded_at'] as String?,
      farmId: json['farm_id'] as String?,
      target: json['target'] as String?,
      question: json['question'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'problem_id': problemId,
        'due_at': dueAt,
        if (response != null) 'response': response,
        if (imageAssetId != null) 'image_asset_id': imageAssetId,
        if (respondedAt != null) 'responded_at': respondedAt,
        if (farmId != null) 'farm_id': farmId,
        if (target != null) 'target': target,
        if (question != null) 'question': question,
      };
}

class PendingFollowUpsResponse {
  final List<FollowUpModel> followups;

  List<FollowUpModel> get followUps => followups;
  List<FollowUpModel> get items => followups;
  int get count => followups.length;

  const PendingFollowUpsResponse({
    List<FollowUpModel>? followups,
    List<FollowUpModel>? followUps,
    int? count,
  }) : followups = followups ?? followUps ?? const [];

  factory PendingFollowUpsResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['followups'] as List<dynamic>?)
            ?.map((e) => FollowUpModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return PendingFollowUpsResponse(followups: list);
  }

  Map<String, dynamic> toJson() => {
        'followups': followups.map((e) => e.toJson()).toList(),
      };
}

class SeverityChangeModel {
  final String from;
  final String to;

  const SeverityChangeModel({required this.from, required this.to});

  factory SeverityChangeModel.fromJson(Map<String, dynamic> json) {
    return SeverityChangeModel(
      from: json['from'] as String,
      to: json['to'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'from': from,
        'to': to,
      };
}

class FollowUpResultModel {
  final String problemId;
  final SeverityChangeModel? severityChange;
  final HealthModel? health;
  final bool? escalated;
  final String? caseId;

  String get status => 'recorded';

  const FollowUpResultModel({
    String? problemId,
    String? status,
    this.severityChange,
    this.health,
    this.escalated,
    this.caseId,
  }) : problemId = problemId ?? '';

  factory FollowUpResultModel.fromJson(Map<String, dynamic> json) {
    return FollowUpResultModel(
      problemId: json['problem_id'] as String? ?? '',
      severityChange: json['severity_change'] != null
          ? SeverityChangeModel.fromJson(
              json['severity_change'] as Map<String, dynamic>)
          : null,
      health: json['health'] != null
          ? HealthModel.fromJson(json['health'] as Map<String, dynamic>)
          : null,
      escalated: json['escalated'] as bool?,
      caseId: json['case_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'problem_id': problemId,
        if (severityChange != null) 'severity_change': severityChange!.toJson(),
        if (health != null) 'health': health!.toJson(),
        if (escalated != null) 'escalated': escalated,
        if (caseId != null) 'case_id': caseId,
      };
}
