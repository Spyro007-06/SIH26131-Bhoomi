/// Centralized API endpoint paths for Bhoomi v2 backend.
/// Base path is `/api/v1` (API_CONTRACT §0).
abstract final class ApiEndpoints {
  // Authentication (OTP only for Farmer App - API_CONTRACT §2)
  static const String authOtpRequest = '/auth/otp/request';
  static const String authOtpVerify = '/auth/otp/verify';

  // Assets & Media
  static const String assetsPresign = '/assets/presign';

  // Voice Interaction
  static const String voiceTranscribe = '/voice/transcribe';
  static const String voiceSynthesize = '/voice/synthesize';

  // Farm Profile & Memory
  static const String farms = '/farms';
  static String farmDetail(String farmId) => '/farms/$farmId';
  static String farmSummary(String farmId) => '/farms/$farmId/summary';

  // Diagnosis Choke Point
  static String diagnose(String farmId) => '/farms/$farmId/diagnose';

  // Doubt Doctor Resolution
  static String clarify(String problemId) => '/problems/$problemId/clarify';

  // Advisory Query (Standalone RAG)
  static const String advisoryQuery = '/advisory/query';

  // Pesticide Label Check (OCR Veto)
  static String labelCheck(String problemId) => '/problems/$problemId/label-check';

  // Risk Alerts & Surveillance
  static String alerts(String farmId) => '/farms/$farmId/alerts';
  static String alertRespond(String alertId) => '/alerts/$alertId/respond';

  // Problem History & Escalation
  static String problems(String farmId) => '/farms/$farmId/problems';
  static String problemDetail(String problemId) => '/problems/$problemId';
  static String escalate(String problemId) => '/problems/$problemId/escalate';

  // Timeline (Case File)
  static String timeline(String farmId) => '/farms/$farmId/timeline';

  // Closed-Loop Follow-ups
  static String pendingFollowUps(String farmId) => '/farms/$farmId/followups/pending';
  static String followUpRespond(String followUpId) => '/followups/$followUpId/respond';

  // Referral & Helpline
  static String referrals(String farmId) => '/farms/$farmId/referrals';

  // System Health
  static const String health = '/health';
}
