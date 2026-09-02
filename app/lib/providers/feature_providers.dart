import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/alert_models.dart';
import '../models/followup_models.dart';
import '../models/timeline_models.dart';
import '../models/problem_models.dart';
import '../models/referral_models.dart';
import 'repository_providers.dart';

/// Provider for active risk alerts for a farm.
final activeAlertsProvider =
    FutureProvider.family<AlertsResponse, String>((ref, farmId) async {
  final repo = ref.read(alertRepositoryProvider);
  return repo.getAlerts(farmId: farmId);
});

/// Provider for pending closed-loop follow-ups for a farm.
final pendingFollowUpsProvider =
    FutureProvider.family<PendingFollowUpsResponse, String>((ref, farmId) async {
  final repo = ref.read(followUpRepositoryProvider);
  return repo.getPendingFollowUps(farmId);
});

/// Provider for crop timeline history for a farm.
final farmTimelineProvider =
    FutureProvider.family<TimelineResponse, String>((ref, farmId) async {
  final repo = ref.read(timelineRepositoryProvider);
  return repo.getTimeline(farmId: farmId);
});

/// Provider for problem detail by problem ID.
final problemDetailProvider =
    FutureProvider.family<ProblemDetailModel, String>((ref, problemId) async {
  final repo = ref.read(problemRepositoryProvider);
  return repo.getProblemDetail(problemId);
});

/// Provider for KVK and agricultural referrals for a farm.
final farmReferralsProvider =
    FutureProvider.family<ReferralsResponse, String>((ref, farmId) async {
  final repo = ref.read(referralRepositoryProvider);
  return repo.getReferrals(farmId);
});
