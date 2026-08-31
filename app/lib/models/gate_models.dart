/// Confidence gate wire models matching DESIGN.md C1, C3 and API_CONTRACT §6.

class Prediction {
  final String label; // blast | brown_spot | bacterial_leaf_blight | yellow_stem_borer | brown_planthopper
  final double confidence; // 0.0 - 1.0

  const Prediction({
    required this.label,
    required this.confidence,
  });

  factory Prediction.fromJson(Map<String, dynamic> json) {
    return Prediction(
      label: json['label'] as String,
      confidence: (json['confidence'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'confidence': confidence,
      };
}

class GateDecision {
  final String outcome; // advise | clarify | escalate
  final double confidence;
  final double thresholdApplied;
  final String reasonCode; // ABOVE_GATE | AMBIGUOUS | BELOW_FLOOR | OUT_OF_SCOPE | NO_RELEVANT_SOURCE
  final List<Prediction> alternatives; // Always populated across all 3 outcomes
  final bool isStub; // True -> UI must render StubBanner

  const GateDecision({
    required this.outcome,
    required this.confidence,
    required this.thresholdApplied,
    required this.reasonCode,
    required this.alternatives,
    this.isStub = false,
  });

  bool get isAdvise => outcome == 'advise';
  bool get isClarify => outcome == 'clarify';
  bool get isEscalate => outcome == 'escalate';

  factory GateDecision.fromJson(Map<String, dynamic> json) {
    final altsList = (json['alternatives'] as List<dynamic>?)
            ?.map((e) => Prediction.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return GateDecision(
      outcome: json['outcome'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      thresholdApplied: (json['threshold_applied'] as num).toDouble(),
      reasonCode: json['reason_code'] as String,
      alternatives: altsList,
      isStub: json['is_stub'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'outcome': outcome,
        'confidence': confidence,
        'threshold_applied': thresholdApplied,
        'reason_code': reasonCode,
        'alternatives': alternatives.map((e) => e.toJson()).toList(),
        'is_stub': isStub,
      };
}
