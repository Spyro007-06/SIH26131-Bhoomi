/// Frozen wire enums, gate constants, and verbatim verdict strings for Bhoomi v2.
/// Reference: docs/API_CONTRACT.md and docs/DESIGN.md.
abstract final class AppConstants {
  // Gate Threshold Constants (docs/DESIGN.md §6)
  static const double gateThreshold = 0.70;
  static const double floorThreshold = 0.45;
  static const double marginThreshold = 0.15;

  // Gate Outcomes (API_CONTRACT §1)
  static const String outcomeAdvise = 'advise';
  static const String outcomeClarify = 'clarify';
  static const String outcomeEscalate = 'escalate';

  // Gate Reason Codes (API_CONTRACT §1)
  static const String reasonAboveGate = 'ABOVE_GATE';
  static const String reasonAmbiguous = 'AMBIGUOUS';
  static const String reasonBelowFloor = 'BELOW_FLOOR';
  static const String reasonOutOfScope = 'OUT_OF_SCOPE';
  static const String reasonNoRelevantSource = 'NO_RELEVANT_SOURCE';

  // Fixed Server Verdict Strings (docs/DESIGN.md §9, API_CONTRACT §9)
  // Non-negotiable: Rendered verbatim. No string contains "safe" or endorsement phrasing.
  static const Map<String, String> verdictMessages = {
    'NO_OBJECTION_FOUND':
        'No objection found. Follow the printed label for dosage.',
    'NOT_REGISTERED_FOR_TARGET':
        'This product is not registered for this pest. Do not use it here.',
    'WRONG_CROP': 'This product is not registered for paddy.',
    'WRONG_CLASS': 'This is a fungicide. Your problem is an insect pest.',
    'PHI_CONFLICT':
        'Harvest is too close. This product needs more days before harvest.',
    'NOT_IN_RECORDS':
        'I do not have a record of this product. Ask an expert before using it.',
  };

  // Supported Locales
  static const String langMarathi = 'mr-IN';
  static const String langHindi = 'hi-IN';
  static const String langEnglish = 'en-IN';

  // Target Labels display mapping
  static const Map<String, Map<String, String>> targetDisplayNames = {
    'blast': {
      'en': 'Paddy Blast',
      'mr': 'भातावरील करपा',
      'hi': 'धान का झुलसा रोग',
    },
    'brown_spot': {
      'en': 'Brown Spot',
      'mr': 'तपकिरी ठिपके',
      'hi': 'भूरा धब्बा रोग',
    },
    'bacterial_leaf_blight': {
      'en': 'Bacterial Leaf Blight (BLB)',
      'mr': 'जीवाणूजन्य करपा',
      'hi': 'जीवाणु पत्ती झुलसा',
    },
    'yellow_stem_borer': {
      'en': 'Yellow Stem Borer',
      'mr': 'खोडकिडा',
      'hi': 'तने का पीला छेदक',
    },
    'brown_planthopper': {
      'en': 'Brown Planthopper (BPH)',
      'mr': 'तुडतुडे (तपकिरी मावा)',
      'hi': 'भूरा माहू / फुदका',
    },
  };
}
