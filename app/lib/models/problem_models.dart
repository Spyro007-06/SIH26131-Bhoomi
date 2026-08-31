import 'advisory_models.dart';
import 'diagnosis_models.dart';

/// Problem history and observation wire models matching API_CONTRACT §11.

class ProblemModel {
  final String id;
  final String? farmId;
  final String problemType; // disease | pest
  final String label; // blast | brown_spot | bacterial_leaf_blight | yellow_stem_borer | brown_planthopper
  final String severity; // early | moderate | severe
  final String status; // open | resolved
  final String openedAt;
  final String? resolvedAt;

  const ProblemModel({
    required this.id,
    this.farmId,
    required this.problemType,
    required this.label,
    required this.severity,
    required this.status,
    required this.openedAt,
    this.resolvedAt,
  });

  factory ProblemModel.fromJson(Map<String, dynamic> json) {
    return ProblemModel(
      id: json['id'] as String,
      farmId: json['farm_id'] as String?,
      problemType: json['problem_type'] as String? ?? 'disease',
      label: json['label'] as String,
      severity: json['severity'] as String? ?? 'early',
      status: json['status'] as String? ?? 'open',
      openedAt: json['opened_at'] as String,
      resolvedAt: json['resolved_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (farmId != null) 'farm_id': farmId,
        'problem_type': problemType,
        'label': label,
        'severity': severity,
        'status': status,
        'opened_at': openedAt,
        if (resolvedAt != null) 'resolved_at': resolvedAt,
      };
}

class ProblemsResponse {
  final List<ProblemModel> problems;
  final String? nextCursor;

  const ProblemsResponse({
    required this.problems,
    this.nextCursor,
  });

  factory ProblemsResponse.fromJson(Map<String, dynamic> json) {
    final problemsList = (json['problems'] as List<dynamic>?)
            ?.map((e) => ProblemModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return ProblemsResponse(
      problems: problemsList,
      nextCursor: json['next_cursor'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'problems': problems.map((e) => e.toJson()).toList(),
        if (nextCursor != null) 'next_cursor': nextCursor,
      };
}

class ObservationModel {
  final String? id;
  final String? problemId;
  final String? kind; // doubt_doctor | field_note
  final String question;
  final String answer; // yes | no | unknown
  final String? cueId;
  final String? createdAt;

  const ObservationModel({
    this.id,
    this.problemId,
    this.kind,
    required this.question,
    required this.answer,
    this.cueId,
    this.createdAt,
  });

  factory ObservationModel.fromJson(Map<String, dynamic> json) {
    return ObservationModel(
      id: json['id'] as String?,
      problemId: json['problem_id'] as String?,
      kind: json['kind'] as String?,
      question: json['question'] as String,
      answer: json['answer'] as String,
      cueId: json['cue_id'] as String?,
      createdAt: json['created_at'] as String? ?? json['at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (problemId != null) 'problem_id': problemId,
        if (kind != null) 'kind': kind,
        'question': question,
        'answer': answer,
        if (cueId != null) 'cue_id': cueId,
        if (createdAt != null) 'created_at': createdAt,
      };
}

class ProblemDetailModel {
  final ProblemModel problem;
  final List<ObservationModel> observations;
  final AdvisoryModel? advisory;
  final List<String> imageUrls;
  final EscalationModel? escalation;

  String get id => problem.id;
  String? get farmId => problem.farmId;
  String get problemType => problem.problemType;
  String get label => problem.label;
  String get severity => problem.severity;
  String get status => problem.status;
  String get openedAt => problem.openedAt;
  String? get resolvedAt => problem.resolvedAt;

  ProblemDetailModel({
    ProblemModel? problem,
    String? id,
    String? farmId,
    String? crop,
    String? type,
    String? label,
    String? severity,
    String? status,
    String? openedAt,
    String? resolvedAt,
    this.observations = const [],
    this.advisory,
    this.imageUrls = const [],
    this.escalation,
  }) : problem = problem ??
            ProblemModel(
              id: id ?? '',
              farmId: farmId,
              problemType: type ?? 'disease',
              label: label ?? '',
              severity: severity ?? 'early',
              status: status ?? 'open',
              openedAt: openedAt ?? '',
              resolvedAt: resolvedAt,
            );

  factory ProblemDetailModel.fromJson(Map<String, dynamic> json) {
    final observationsList = (json['observations'] as List<dynamic>?)
            ?.map((e) => ObservationModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final imagesList = (json['images'] as List<dynamic>?)
            ?.map((e) => e is Map ? (e['url'] as String? ?? '') : e.toString())
            .toList() ??
        [];

    return ProblemDetailModel(
      problem: ProblemModel.fromJson(json['problem'] != null
          ? json['problem'] as Map<String, dynamic>
          : json),
      observations: observationsList,
      advisory: json['advisory'] != null
          ? AdvisoryModel.fromJson(json['advisory'] as Map<String, dynamic>)
          : null,
      imageUrls: imagesList,
      escalation: json['escalation'] != null
          ? EscalationModel.fromJson(json['escalation'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'problem': problem.toJson(),
        'observations': observations.map((e) => e.toJson()).toList(),
        if (advisory != null) 'advisory': advisory!.toJson(),
        'images': imageUrls,
        if (escalation != null) 'escalation': escalation!.toJson(),
      };
}
