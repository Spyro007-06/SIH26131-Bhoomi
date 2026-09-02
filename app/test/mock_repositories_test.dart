import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bhoomi/core/network/api_client.dart';
import 'package:bhoomi/core/network/api_config.dart';
import 'package:bhoomi/core/storage/token_storage.dart';
import 'package:bhoomi/repositories/auth_repository.dart';
import 'package:bhoomi/repositories/farm_repository.dart';
import 'package:bhoomi/repositories/diagnosis_repository.dart';
import 'package:bhoomi/repositories/doubt_doctor_repository.dart';
import 'package:bhoomi/repositories/alert_repository.dart';
import 'package:bhoomi/repositories/followup_repository.dart';
import 'package:bhoomi/repositories/timeline_repository.dart';
import 'package:bhoomi/repositories/referral_repository.dart';
import 'package:bhoomi/repositories/health_repository.dart';
import 'package:bhoomi/models/farm_models.dart';
import 'package:bhoomi/core/storage/secure_storage.dart';

class MockInMemoryStorage extends SecureStorage {
  final Map<String, String> _map = {};
  @override
  Future<void> write({required String key, required String value}) async => _map[key] = value;
  @override
  Future<String?> read({required String key}) async => _map[key];
  @override
  Future<void> delete({required String key}) async => _map.remove(key);
}

class MockHttpApiClient extends ApiClient {
  final Map<String, dynamic> responses = {};
  String? lastGetPath;
  String? lastPostPath;
  dynamic lastPostData;

  MockHttpApiClient()
      : super(
          config: const ApiConfig(),
          tokenStorage: TokenStorage(storage: MockInMemoryStorage()),
        );

  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    lastGetPath = path;
    return responses[path] ?? {};
  }

  @override
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    lastPostPath = path;
    lastPostData = data;
    return responses[path] ?? {};
  }
}

void main() {
  group('Repository Layer Unit Tests', () {
    late MockHttpApiClient mockClient;
    late TokenStorage tokenStorage;

    setUp(() {
      mockClient = MockHttpApiClient();
      tokenStorage = TokenStorage(storage: MockInMemoryStorage());
    });

    test('AuthRepository handles OTP request and verification', () async {
      final authRepo = AuthRepositoryImpl(
        apiClient: mockClient,
        tokenStorage: tokenStorage,
      );

      mockClient.responses['/auth/otp/request'] = {
        'request_id': 'req_777',
        'expires_in': 300,
      };
      mockClient.responses['/auth/otp/verify'] = {
        'access_token': 'jwt_access_abc',
        'refresh_token': 'jwt_refresh_def',
        'user': {'id': 'u_farmer_1', 'phone': '+919876543210', 'role': 'farmer'},
      };

      final reqRes = await authRepo.requestOtp(phone: '+919876543210');
      expect(reqRes.requestId, 'req_777');
      expect(mockClient.lastPostPath, '/auth/otp/request');

      final verifyRes = await authRepo.verifyOtp(requestId: 'req_777', otp: '123456');
      expect(verifyRes.accessToken, 'jwt_access_abc');
      expect(verifyRes.user.id, 'u_farmer_1');

      // Verify tokens were saved to TokenStorage
      expect(await tokenStorage.getAccessToken(), 'jwt_access_abc');
      expect(await authRepo.isAuthenticated(), isTrue);
    });

    test('FarmRepository handles farm creation and summary queries', () async {
      final farmRepo = FarmRepositoryImpl(apiClient: mockClient);

      mockClient.responses['/farms'] = {
        'id': 'f_100',
        'crop': 'paddy',
        'variety': 'Indrayani',
        'growth_stage': 'tillering',
        'region': 'Nashik',
        'location': {'lat': 19.99, 'lng': 73.78},
      };

      final createdFarm = await farmRepo.createFarm(
        crop: 'paddy',
        variety: 'Indrayani',
        growthStage: 'tillering',
        region: 'Nashik',
        location: const GeoPoint(lat: 19.99, lng: 73.78),
      );

      expect(createdFarm.id, 'f_100');
      expect(mockClient.lastPostPath, '/farms');
      expect(mockClient.lastPostData['crop'], 'paddy');
      expect(mockClient.lastPostData['growth_stage'], 'tillering');

      mockClient.responses['/farms/f_100/summary'] = {
        'farm': createdFarm.toJson(),
        'health': {'sentence': 'Crop is healthy.', 'trend': 'improving'},
        'open_problems': 0,
        'pending_followups': 0,
        'active_alerts': 0,
      };

      final summary = await farmRepo.getFarmSummary('f_100');
      expect(summary.farm.id, 'f_100');
      expect(summary.health.sentence, 'Crop is healthy.');
      expect(summary.health.trend, 'improving');
    });

    test('DiagnosisRepository submits image asset reference to confidence gate', () async {
      final diagnosisRepo = DiagnosisRepositoryImpl(apiClient: mockClient);

      mockClient.responses['/farms/f_100/diagnose'] = {
        'gate': {
          'outcome': 'advise',
          'confidence': 0.91,
          'threshold_applied': 0.70,
          'reason_code': 'ABOVE_GATE',
          'alternatives': [
            {'label': 'blast', 'confidence': 0.91}
          ],
        },
        'problem_id': 'p_1',
        'problem_type': 'disease',
        'diagnosis': {'label': 'blast', 'severity': 'early', 'confidence': 0.91},
        'advisory': {
          'possible_issue': 'Paddy Blast',
          'what_to_check': 'Diamond spots',
          'what_to_avoid': 'No nitrogen',
          'ladder': [],
        },
      };

      final response = await diagnosisRepo.diagnose(
        farmId: 'f_100',
        imageAssetId: 'a_photo_1',
        descriptionText: 'पानांवर ठिपके',
      );

      expect(response.isAdvise, isTrue);
      expect(response.problemId, 'p_1');
      expect(mockClient.lastPostPath, '/farms/f_100/diagnose');
      expect(mockClient.lastPostData['image_asset_id'], 'a_photo_1');
    });

    test('DoubtDoctorRepository submits field observation answer', () async {
      final doubtDoctorRepo = DoubtDoctorRepositoryImpl(apiClient: mockClient);

      mockClient.responses['/problems/p_1/clarify'] = {
        'resolved': true,
        'observation_id': 'obs_1',
        'diagnosis': {'label': 'blast', 'severity': 'early', 'resolved_by': 'field_observation'},
        'advisory': {
          'possible_issue': 'Blast',
          'what_to_check': 'Lesions',
          'what_to_avoid': 'Avoid urea',
          'ladder': [],
        },
      };

      final result = await doubtDoctorRepo.submitAnswer(
        problemId: 'p_1',
        cueId: 'cue_4',
        answer: 'yes',
      );

      expect(result.resolved, isTrue);
      expect(result.observationId, 'obs_1');
      expect(mockClient.lastPostPath, '/problems/p_1/clarify');
      expect(mockClient.lastPostData['cue_id'], 'cue_4');
      expect(mockClient.lastPostData['answer'], 'yes');
    });

    test('AlertRepository queries alerts and posts response outcome', () async {
      final alertRepo = AlertRepositoryImpl(apiClient: mockClient);

      mockClient.responses['/farms/f_100/alerts'] = {
        'alerts': [
          {
            'id': 'al_1',
            'trigger_type': 'weather',
            'target': 'blast',
            'risk_level': 'high',
            'reason': 'High humidity',
            'inspection_tasks': ['Inspect stem base'],
            'issued_at': '2026-08-30T00:00:00Z',
          }
        ]
      };

      final alerts = await alertRepo.getAlerts(farmId: 'f_100');
      expect(alerts.alerts.length, 1);
      expect(alerts.alerts[0].id, 'al_1');
      expect(alerts.alerts[0].inspectionTasks, ['Inspect stem base']);

      mockClient.responses['/alerts/al_1/respond'] = {
        'alert_id': 'al_1',
        'outcome': 'found',
        'diagnose_suggested': true,
      };

      final respondRes = await alertRepo.respondToAlert(
        alertId: 'al_1',
        outcome: 'found',
      );
      expect(respondRes.alertId, 'al_1');
      expect(respondRes.outcome, 'found');
      expect(respondRes.diagnoseSuggested, isTrue);
    });

    test('FollowUpRepository queries pending follow-ups and records responses', () async {
      final followUpRepo = FollowUpRepositoryImpl(apiClient: mockClient);

      mockClient.responses['/farms/f_100/followups/pending'] = {
        'followups': [
          {'id': 'fu_1', 'problem_id': 'p_1', 'due_at': '2026-08-31T00:00:00Z'}
        ]
      };

      final pending = await followUpRepo.getPendingFollowUps('f_100');
      expect(pending.followups.length, 1);
      expect(pending.followups[0].id, 'fu_1');

      mockClient.responses['/followups/fu_1/respond'] = {
        'problem_id': 'p_1',
        'severity_change': {'from': 'early', 'to': 'moderate'},
        'escalated': false,
      };

      final res = await followUpRepo.respondToFollowUp(
        followUpId: 'fu_1',
        response: 'no_change',
      );
      expect(res.problemId, 'p_1');
      expect(res.severityChange?.from, 'early');
    });

    test('TimelineRepository, ReferralRepository, and HealthRepository work as expected', () async {
      final timelineRepo = TimelineRepositoryImpl(apiClient: mockClient);
      final referralRepo = ReferralRepositoryImpl(apiClient: mockClient);
      final healthRepo = HealthRepositoryImpl(apiClient: mockClient);

      mockClient.responses['/farms/f_100/timeline'] = {
        'events': [
          {
            'id': 'ev_1',
            'type': 'diagnosis',
            'title': 'Diagnosed with Paddy Blast',
            'timestamp': '2026-08-25T10:00:00Z',
          }
        ]
      };

      final timeline = await timelineRepo.getTimeline(farmId: 'f_100');
      expect(timeline.events.length, 1);
      expect(timeline.events[0].title, 'Diagnosed with Paddy Blast');

      mockClient.responses['/farms/f_100/referrals'] = {
        'referrals': [
          {
            'kind': 'helpline',
            'name': 'Kisan Call Centre',
            'phone': '1800-180-1551',
            'accepts_samples': false,
          }
        ]
      };

      final referrals = await referralRepo.getReferrals('f_100');
      expect(referrals.referrals.length, 1);
      expect(referrals.referrals[0].phone, '1800-180-1551');

      mockClient.responses['/health'] = {
        'status': 'ok',
        'version': '2.0.0',
        'vision_model': 'stub',
        'is_stub': true,
      };

      final health = await healthRepo.getHealth();
      expect(health.status, 'ok');
      expect(health.isStub, isTrue);
    });
  });
}
