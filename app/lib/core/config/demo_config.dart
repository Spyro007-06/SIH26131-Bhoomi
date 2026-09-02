/// Centralized configuration for SIH Demo Mode and Demo Account.
///
/// Demo mode allows the SIH team and judges to explore the full Bhoomi
/// Farmer application workflow with a pre-configured demo farmer identity
/// without needing an active SMS/OTP delivery network.
///
/// Can be toggled at build/run time via:
/// `--dart-define=DEMO_MODE=true` (or `false`)
class DemoConfig {
  /// Whether Demo Mode and the Demo Account entry point are enabled.
  /// Defaults to true for local/evaluation builds.
  static const bool isDemoMode = bool.fromEnvironment(
    'DEMO_MODE',
    defaultValue: true,
  );

  /// Authorization code for demo authentication endpoint.
  static const String demoCode = 'SIH2026';

  // Demo Farmer Identity
  static const String demoFarmerId = 'u_demo_01';
  static const String demoFarmerName = 'Ramesh Patil';
  static const String demoPhone = '+919999999999';
  static const String demoRole = 'farmer';

  // Demo Farm Profile
  static const String demoFarmId = 'f_demo_01';
  static const String demoFarmName = 'Demo Paddy Farm (भात शेत)';
  static const String demoLocation = 'Nashik, Maharashtra';
  static const String demoCrop = 'paddy';
  static const String demoVariety = 'Indrayani';
  static const String demoGrowthStage = 'tillering';
  static const double demoLatitude = 19.99730;
  static const double demoLongitude = 73.74140;
}
