import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/auth_repository.dart';
import '../repositories/farm_repository.dart';
import '../repositories/asset_repository.dart';
import '../repositories/voice_repository.dart';
import '../repositories/diagnosis_repository.dart';
import '../repositories/doubt_doctor_repository.dart';
import '../repositories/problem_repository.dart';
import '../repositories/advisory_repository.dart';
import '../repositories/label_check_repository.dart';
import '../repositories/alert_repository.dart';
import '../repositories/followup_repository.dart';
import '../repositories/timeline_repository.dart';
import '../repositories/referral_repository.dart';
import '../repositories/health_repository.dart';
import 'network_providers.dart';
import 'storage_providers.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return AuthRepositoryImpl(
    apiClient: apiClient,
    tokenStorage: tokenStorage,
  );
});

final farmRepositoryProvider = Provider<FarmRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return FarmRepositoryImpl(apiClient: apiClient);
});

final assetRepositoryProvider = Provider<AssetRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AssetRepositoryImpl(apiClient: apiClient);
});

final voiceRepositoryProvider = Provider<VoiceRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return VoiceRepositoryImpl(apiClient: apiClient);
});

final diagnosisRepositoryProvider = Provider<DiagnosisRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DiagnosisRepositoryImpl(apiClient: apiClient);
});

final doubtDoctorRepositoryProvider = Provider<DoubtDoctorRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DoubtDoctorRepositoryImpl(apiClient: apiClient);
});

final problemRepositoryProvider = Provider<ProblemRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProblemRepositoryImpl(apiClient: apiClient);
});

final advisoryRepositoryProvider = Provider<AdvisoryRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AdvisoryRepositoryImpl(apiClient: apiClient);
});

final labelCheckRepositoryProvider = Provider<LabelCheckRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return LabelCheckRepositoryImpl(apiClient: apiClient);
});

final alertRepositoryProvider = Provider<AlertRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AlertRepositoryImpl(apiClient: apiClient);
});

final followUpRepositoryProvider = Provider<FollowUpRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return FollowUpRepositoryImpl(apiClient: apiClient);
});

final timelineRepositoryProvider = Provider<TimelineRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TimelineRepositoryImpl(apiClient: apiClient);
});

final referralRepositoryProvider = Provider<ReferralRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ReferralRepositoryImpl(apiClient: apiClient);
});

final healthRepositoryProvider = Provider<HealthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return HealthRepositoryImpl(apiClient: apiClient);
});
