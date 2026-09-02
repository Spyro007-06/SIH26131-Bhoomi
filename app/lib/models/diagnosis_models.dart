import 'gate_models.dart';
import 'advisory_models.dart';

/// Diagnosis, Doubt Doctor, and Escalation models matching API_CONTRACT §6 and §7.

class CandidateModel {
  final String label;
  final String signature;
  final String? imageUrl;

  const CandidateModel({
    required this.label,
    required this.signature,
    this.imageUrl,
  });

  factory CandidateModel.fromJson(Map<String, dynamic> json) {
    return CandidateModel(
      label: json['label'] as String,
      signature: json['signature'] as String,
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'signature': signature,
        if (imageUrl != null) 'image_url': imageUrl,
      };
}

class ClarificationModel {
  final String cueId;
  final String question;
  final String? questionLocalized;
  final List<CandidateModel> candidates;
  final List<String> answers; // ["yes", "no", "unknown"]

  const ClarificationModel({
    required this.cueId,
    required this.question,
    this.questionLocalized,
    required this.candidates,
    this.answers = const ['yes', 'no', 'unknown'],
  });

  factory ClarificationModel.fromJson(Map<String, dynamic> json) {
    final candidatesList = (json['candidates'] as List<dynamic>?)
            ?.map((e) => CandidateModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final answersList = (json['answers'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        ['yes', 'no', 'unknown'];

    return ClarificationModel(
      cueId: json['cue_id'] as String,
      question: json['question'] as String,
      questionLocalized: json['question_localized'] as String?,
      candidates: candidatesList,
      answers: answersList,
    );
  }

  Map<String, dynamic> toJson() => {
        'cue_id': cueId,
        'question': question,
        if (questionLocalized != null) 'question_localized': questionLocalized,
        'candidates': candidates.map((e) => e.toJson()).toList(),
        'answers': answers,
      };
}

class EscalationModel {
  final String caseId;
  final String assignedTo;
  final int? queuePosition;
  final int? etaMinutes;
  final String? status; // open | assigned | resolved

  const EscalationModel({
    required this.caseId,
    required this.assignedTo,
    this.queuePosition,
    this.etaMinutes,
    this.status,
  });

  factory EscalationModel.fromJson(Map<String, dynamic> json) {
    return EscalationModel(
      caseId: json['case_id'] as String,
      assignedTo: json['assigned_to'] as String,
      queuePosition: json['queue_position'] as int?,
      etaMinutes: json['eta_minutes'] as int?,
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'case_id': caseId,
        'assigned_to': assignedTo,
        if (queuePosition != null) 'queue_position': queuePosition,
        if (etaMinutes != null) 'eta_minutes': etaMinutes,
        if (status != null) 'status': status,
      };
}

class DiagnosisDetail {
  final String label;
  final String severity; // early | moderate | severe
  final double? confidence;
  final String? resolvedBy; // model | field_observation | agronomist

  const DiagnosisDetail({
    required this.label,
    required this.severity,
    this.confidence,
    this.resolvedBy,
  });

  factory DiagnosisDetail.fromJson(Map<String, dynamic> json) {
    return DiagnosisDetail(
      label: json['label'] as String,
      severity: json['severity'] as String? ?? 'early',
      confidence: (json['confidence'] as num?)?.toDouble(),
      resolvedBy: json['resolved_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'severity': severity,
        if (confidence != null) 'confidence': confidence,
        if (resolvedBy != null) 'resolved_by': resolvedBy,
      };
}

/// Polymorphic response returned by `POST /farms/{id}/diagnose` (API_CONTRACT §6).
/// Exactly one outcome appears: advise, clarify, or escalate.
class DiagnoseResponse {
  final GateDecision gate;
  final String? problemId;
  final String? problemType; // disease | pest
  final DiagnosisDetail? diagnosis;
  final AdvisoryModel? advisory; // Present ONLY on advise branch
  final List<CitationModel> citations;
  final ClarificationModel? clarification; // Present ONLY on clarify branch
  final EscalationModel? escalation; // Present ONLY on escalate branch
  final String? spokenSummary;

  const DiagnoseResponse({
    required this.gate,
    this.problemId,
    this.problemType,
    this.diagnosis,
    this.advisory,
    this.citations = const [],
    this.clarification,
    this.escalation,
    this.spokenSummary,
  });

  bool get isAdvise => gate.isAdvise;
  bool get isClarify => gate.isClarify;
  bool get isEscalate => gate.isEscalate;

  factory DiagnoseResponse.fromJson(Map<String, dynamic> json) {
    final gate = GateDecision.fromJson(json['gate'] as Map<String, dynamic>);
    final citationsList = (json['citations'] as List<dynamic>?)
            ?.map((e) => CitationModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return DiagnoseResponse(
      gate: gate,
      problemId: json['problem_id'] as String?,
      problemType: json['problem_type'] as String?,
      diagnosis: json['diagnosis'] != null
          ? DiagnosisDetail.fromJson(json['diagnosis'] as Map<String, dynamic>)
          : null,
      advisory: json['advisory'] != null
          ? AdvisoryModel.fromJson(json['advisory'] as Map<String, dynamic>)
          : null,
      citations: citationsList,
      clarification: json['clarification'] != null
          ? ClarificationModel.fromJson(
              json['clarification'] as Map<String, dynamic>)
          : null,
      escalation: json['escalation'] != null
          ? EscalationModel.fromJson(json['escalation'] as Map<String, dynamic>)
          : null,
      spokenSummary: json['spoken_summary'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'gate': gate.toJson(),
        if (problemId != null) 'problem_id': problemId,
        if (problemType != null) 'problem_type': problemType,
        if (diagnosis != null) 'diagnosis': diagnosis!.toJson(),
        if (advisory != null) 'advisory': advisory!.toJson(),
        'citations': citations.map((e) => e.toJson()).toList(),
        if (clarification != null) 'clarification': clarification!.toJson(),
        if (escalation != null) 'escalation': escalation!.toJson(),
        if (spokenSummary != null) 'spoken_summary': spokenSummary,
      };
}

/// Result returned after submitting Doubt Doctor answer `POST /problems/{id}/clarify` (API_CONTRACT §7).
class DoubtDoctorAnswerResult {
  final bool resolved;
  final String? reason;
  final String? observationId;
  final DiagnosisDetail? diagnosis;
  final AdvisoryModel? advisory;
  final List<CitationModel> citations;
  final EscalationModel? escalation;
  final String? spokenSummary;

  const DoubtDoctorAnswerResult({
    required this.resolved,
    this.reason,
    this.observationId,
    this.diagnosis,
    this.advisory,
    this.citations = const [],
    this.escalation,
    this.spokenSummary,
  });

  factory DoubtDoctorAnswerResult.fromJson(Map<String, dynamic> json) {
    final citationsList = (json['citations'] as List<dynamic>?)
            ?.map((e) => CitationModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return DoubtDoctorAnswerResult(
      resolved: json['resolved'] as bool? ?? false,
      reason: json['reason'] as String?,
      observationId: json['observation_id'] as String?,
      diagnosis: json['diagnosis'] != null
          ? DiagnosisDetail.fromJson(json['diagnosis'] as Map<String, dynamic>)
          : null,
      advisory: json['advisory'] != null
          ? AdvisoryModel.fromJson(json['advisory'] as Map<String, dynamic>)
          : null,
      citations: citationsList,
      escalation: json['escalation'] != null
          ? EscalationModel.fromJson(json['escalation'] as Map<String, dynamic>)
          : null,
      spokenSummary: json['spoken_summary'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'resolved': resolved,
        if (reason != null) 'reason': reason,
        if (observationId != null) 'observation_id': observationId,
        if (diagnosis != null) 'diagnosis': diagnosis!.toJson(),
        if (advisory != null) 'advisory': advisory!.toJson(),
        'citations': citations.map((e) => e.toJson()).toList(),
        if (escalation != null) 'escalation': escalation!.toJson(),
        if (spokenSummary != null) 'spoken_summary': spokenSummary,
      };
}
