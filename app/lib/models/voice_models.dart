/// Multilingual voice processing wire models matching API_CONTRACT §4.

class ParsedIntentModel {
  final String field; // e.g. growth_stage, variety, answer
  final String value;

  const ParsedIntentModel({
    required this.field,
    required this.value,
  });

  factory ParsedIntentModel.fromJson(Map<String, dynamic> json) {
    return ParsedIntentModel(
      field: json['field'] as String,
      value: json['value'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'field': field,
        'value': value,
      };
}

class VoiceTranscribeResult {
  final String text;
  final double confidence;
  final String lang; // mr-IN | hi-IN | ta-IN | en-IN
  final ParsedIntentModel? parsedIntent;
  final bool needsConfirmation;

  const VoiceTranscribeResult({
    required this.text,
    required this.confidence,
    required this.lang,
    this.parsedIntent,
    this.needsConfirmation = false,
  });

  factory VoiceTranscribeResult.fromJson(Map<String, dynamic> json) {
    return VoiceTranscribeResult(
      text: json['text'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      lang: json['lang'] as String? ?? 'mr-IN',
      parsedIntent: json['parsed_intent'] != null
          ? ParsedIntentModel.fromJson(
              json['parsed_intent'] as Map<String, dynamic>)
          : null,
      needsConfirmation: json['needs_confirmation'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'text': text,
        'confidence': confidence,
        'lang': lang,
        if (parsedIntent != null) 'parsed_intent': parsedIntent!.toJson(),
        'needs_confirmation': needsConfirmation,
      };
}

class VoiceSynthesizeResult {
  final String audioUrl;
  final int expiresIn;

  const VoiceSynthesizeResult({
    required this.audioUrl,
    this.expiresIn = 600,
  });

  factory VoiceSynthesizeResult.fromJson(Map<String, dynamic> json) {
    return VoiceSynthesizeResult(
      audioUrl: json['audio_url'] as String,
      expiresIn: json['expires_in'] as int? ?? 600,
    );
  }

  Map<String, dynamic> toJson() => {
        'audio_url': audioUrl,
        'expires_in': expiresIn,
      };
}
