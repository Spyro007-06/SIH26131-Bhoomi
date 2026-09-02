/// Advisory and IPM ladder wire models matching API_CONTRACT §8.

class LadderRungModel {
  final String tier; // cultural | biological | chemical (chemical must always be last)
  final String action;
  final String? dosage;
  final int? phiDays;
  final int? reentryHours;

  const LadderRungModel({
    required this.tier,
    required this.action,
    this.dosage,
    this.phiDays,
    this.reentryHours,
  });

  factory LadderRungModel.fromJson(Map<String, dynamic> json) {
    return LadderRungModel(
      tier: json['tier'] as String,
      action: json['action'] as String,
      dosage: json['dosage'] as String?,
      phiDays: json['phi_days'] as int?,
      reentryHours: json['reentry_hours'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'tier': tier,
        'action': action,
        if (dosage != null) 'dosage': dosage,
        if (phiDays != null) 'phi_days': phiDays,
        if (reentryHours != null) 'reentry_hours': reentryHours,
      };
}

class CitationModel {
  final String docId;
  final String title;
  final String reviewedOn;

  const CitationModel({
    required this.docId,
    required this.title,
    required this.reviewedOn,
  });

  factory CitationModel.fromJson(Map<String, dynamic> json) {
    return CitationModel(
      docId: json['doc_id'] as String,
      title: json['title'] as String,
      reviewedOn: json['reviewed_on'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'doc_id': docId,
        'title': title,
        'reviewed_on': reviewedOn,
      };
}

class AdvisoryModel {
  final String possibleIssue;
  final String whatToCheck;
  final String whatToAvoid; // Rendered first and loudest
  final List<LadderRungModel> ladder;
  final String? expertTrigger;

  const AdvisoryModel({
    required this.possibleIssue,
    required this.whatToCheck,
    required this.whatToAvoid,
    required this.ladder,
    this.expertTrigger,
  });

  factory AdvisoryModel.fromJson(Map<String, dynamic> json) {
    final ladderList = (json['ladder'] as List<dynamic>?)
            ?.map((e) => LadderRungModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return AdvisoryModel(
      possibleIssue: json['possible_issue'] as String,
      whatToCheck: json['what_to_check'] as String,
      whatToAvoid: json['what_to_avoid'] as String,
      ladder: ladderList,
      expertTrigger: json['expert_trigger'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'possible_issue': possibleIssue,
        'what_to_check': whatToCheck,
        'what_to_avoid': whatToAvoid,
        'ladder': ladder.map((e) => e.toJson()).toList(),
        if (expertTrigger != null) 'expert_trigger': expertTrigger,
      };
}

class AdvisoryQueryResult {
  final bool retrieved;
  final AdvisoryModel? advisory;
  final List<CitationModel> citations;
  final String? reason;
  final bool? escalationOffered;
  final String? spokenSummary;

  const AdvisoryQueryResult({
    required this.retrieved,
    this.advisory,
    this.citations = const [],
    this.reason,
    this.escalationOffered,
    this.spokenSummary,
  });

  factory AdvisoryQueryResult.fromJson(Map<String, dynamic> json) {
    final citationsList = (json['citations'] as List<dynamic>?)
            ?.map((e) => CitationModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return AdvisoryQueryResult(
      retrieved: json['retrieved'] as bool? ?? false,
      advisory: json['advisory'] != null
          ? AdvisoryModel.fromJson(json['advisory'] as Map<String, dynamic>)
          : null,
      citations: citationsList,
      reason: json['reason'] as String?,
      escalationOffered: json['escalation_offered'] as bool?,
      spokenSummary: json['spoken_summary'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'retrieved': retrieved,
        if (advisory != null) 'advisory': advisory!.toJson(),
        'citations': citations.map((e) => e.toJson()).toList(),
        if (reason != null) 'reason': reason,
        if (escalationOffered != null) 'escalation_offered': escalationOffered,
        if (spokenSummary != null) 'spoken_summary': spokenSummary,
      };
}
