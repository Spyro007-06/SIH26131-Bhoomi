/// Pesticide label check (OCR veto) wire models matching API_CONTRACT §9.

class LabelExtractModel {
  final String? activeIngredient;
  final String? concentration;
  final String? formulation;
  final double ocrConfidence;

  const LabelExtractModel({
    this.activeIngredient,
    this.concentration,
    this.formulation,
    required this.ocrConfidence,
  });

  factory LabelExtractModel.fromJson(Map<String, dynamic> json) {
    return LabelExtractModel(
      activeIngredient: json['active_ingredient'] as String?,
      concentration: json['concentration'] as String?,
      formulation: json['formulation'] as String?,
      ocrConfidence: (json['ocr_confidence'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (activeIngredient != null) 'active_ingredient': activeIngredient,
        if (concentration != null) 'concentration': concentration,
        if (formulation != null) 'formulation': formulation,
        'ocr_confidence': ocrConfidence,
      };
}

class LabelVerdictModel {
  final String code; // NO_OBJECTION_FOUND | NOT_REGISTERED_FOR_TARGET | WRONG_CROP | WRONG_CLASS | PHI_CONFLICT | NOT_IN_RECORDS
  final String message; // Server-supplied verbatim string
  final String? matchedRowId;

  const LabelVerdictModel({
    required this.code,
    required this.message,
    this.matchedRowId,
  });

  factory LabelVerdictModel.fromJson(Map<String, dynamic> json) {
    return LabelVerdictModel(
      code: json['code'] as String,
      message: json['message'] as String,
      matchedRowId: json['matched_row_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'message': message,
        if (matchedRowId != null) 'matched_row_id': matchedRowId,
      };
}

class LabelCheckFallback {
  final List<String> accepts; // ["voice", "text"]

  const LabelCheckFallback({this.accepts = const ['voice', 'text']});

  factory LabelCheckFallback.fromJson(Map<String, dynamic> json) {
    return LabelCheckFallback(
      accepts: (json['accepts'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['voice', 'text'],
    );
  }

  Map<String, dynamic> toJson() => {'accepts': accepts};
}

class LabelCheckError {
  final String code;
  final String message;

  const LabelCheckError({required this.code, required this.message});

  factory LabelCheckError.fromJson(Map<String, dynamic> json) {
    return LabelCheckError(
      code: json['code'] as String,
      message: json['message'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'message': message,
      };
}

class LabelCheckResponse {
  final LabelExtractModel extracted;
  final LabelVerdictModel? verdict;
  final LabelCheckError? error;
  final LabelCheckFallback? fallback;
  final String? spokenSummary;

  const LabelCheckResponse({
    required this.extracted,
    this.verdict,
    this.error,
    this.fallback,
    this.spokenSummary,
  });

  bool get isReadable => verdict != null;

  factory LabelCheckResponse.fromJson(Map<String, dynamic> json) {
    return LabelCheckResponse(
      extracted:
          LabelExtractModel.fromJson(json['extracted'] as Map<String, dynamic>),
      verdict: json['verdict'] != null
          ? LabelVerdictModel.fromJson(json['verdict'] as Map<String, dynamic>)
          : null,
      error: json['error'] != null
          ? LabelCheckError.fromJson(json['error'] as Map<String, dynamic>)
          : null,
      fallback: json['fallback'] != null
          ? LabelCheckFallback.fromJson(
              json['fallback'] as Map<String, dynamic>)
          : null,
      spokenSummary: json['spoken_summary'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'extracted': extracted.toJson(),
        if (verdict != null) 'verdict': verdict!.toJson(),
        if (error != null) 'error': error!.toJson(),
        if (fallback != null) 'fallback': fallback!.toJson(),
        if (spokenSummary != null) 'spoken_summary': spokenSummary,
      };
}
