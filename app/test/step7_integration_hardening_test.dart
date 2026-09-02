import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import 'package:bhoomi/core/theme/app_theme.dart';
import 'package:bhoomi/core/storage/token_storage.dart';
import 'package:bhoomi/core/storage/secure_storage.dart';

import 'package:bhoomi/models/auth_models.dart';
import 'package:bhoomi/models/farm_models.dart';
import 'package:bhoomi/models/gate_models.dart';
import 'package:bhoomi/models/diagnosis_models.dart';
import 'package:bhoomi/models/advisory_models.dart';
import 'package:bhoomi/models/alert_models.dart';
import 'package:bhoomi/models/followup_models.dart';
import 'package:bhoomi/models/asset_models.dart';

import 'package:bhoomi/repositories/auth_repository.dart';
import 'package:bhoomi/repositories/farm_repository.dart';
import 'package:bhoomi/repositories/asset_repository.dart';
import 'package:bhoomi/repositories/diagnosis_repository.dart';
import 'package:bhoomi/repositories/doubt_doctor_repository.dart';
import 'package:bhoomi/repositories/alert_repository.dart';
import 'package:bhoomi/repositories/followup_repository.dart';

import 'package:bhoomi/providers/auth_providers.dart';
import 'package:bhoomi/providers/farm_providers.dart';
import 'package:bhoomi/providers/storage_providers.dart';
import 'package:bhoomi/providers/repository_providers.dart';

import 'package:bhoomi/features/diagnose/presentation/diagnosis_controller.dart';
import 'package:bhoomi/features/diagnose/presentation/advisory_result_screen.dart';
import 'package:bhoomi/features/diagnose/presentation/escalation_status_screen.dart';
import 'package:bhoomi/features/doubt_doctor/presentation/doubt_doctor_screen.dart';
import 'package:bhoomi/features/alerts/presentation/alerts_screen.dart';
import 'package:bhoomi/features/followup/presentation/followups_screen.dart';

// --- In-Memory Secure Storage Mock ---
class MockInMemorySecureStorage extends SecureStorage {
  final Map<String, String> _store = {};

  @override
  Future<void> write({required String key, required String value}) async {
    _store[key] = value;
  }

  @override
  Future<String?> read({required String key}) async {
    return _store[key];
  }

  @override
  Future<void> delete({required String key}) async {
    _store.remove(key);
  }

  @override
  Future<void> deleteAll() async {
    _store.clear();
  }
}

// --- Mock Repositories ---
class MockStep7AuthRepo extends AuthRepository {
  final TokenStorage tokenStorage;
  bool _isAuthenticated = false;
  UserModel? _currentUser;

  MockStep7AuthRepo({required this.tokenStorage});

  @override
  Future<bool> isAuthenticated() async => _isAuthenticated;

  @override
  Future<UserModel?> getCurrentUser() async => _currentUser;

  @override
  Future<OtpRequestResponse> requestOtp({required String phone}) async {
    return const OtpRequestResponse(
      requestId: 'req_otp_test_123',
      expiresIn: 300,
    );
  }

  @override
  Future<OtpVerifyResponse> verifyOtp({
    required String requestId,
    required String otp,
  }) async {
    if (otp == '123456') {
      _isAuthenticated = true;
      _currentUser = const UserModel(
        id: 'u_farmer_step7',
        phone: '+919876543210',
        role: 'farmer',
      );
      await tokenStorage.saveTokens(
        accessToken: 'valid_access_jwt',
        refreshToken: 'valid_refresh_jwt',
      );
      await tokenStorage.saveUserData(_currentUser!.toJson());
      return OtpVerifyResponse(
        accessToken: 'valid_access_jwt',
        refreshToken: 'valid_refresh_jwt',
        user: _currentUser!,
      );
    }
    throw Exception('INVALID_OTP: Invalid verification code');
  }

  @override
  Future<void> logout() async {
    _isAuthenticated = false;
    _currentUser = null;
    await tokenStorage.clearSession();
  }
}

class MockStep7AssetRepo extends AssetRepository {
  @override
  Future<PresignedAssetModel> presignAsset({
    required String kind,
    required String contentType,
    String? farmId,
  }) async {
    return const PresignedAssetModel(
      assetId: 'asset_img_step7_abc',
      uploadUrl: 'https://storage.bhoomi.gov.in/test_upload',
      method: 'PUT',
      expiresIn: 600,
    );
  }

  @override
  Future<void> uploadBinary({
    required String uploadUrl,
    required Uint8List bytes,
    required String contentType,
    ProgressCallback? onProgress,
  }) async {}

  @override
  Future<String> uploadImage({
    required Uint8List bytes,
    String contentType = 'image/jpeg',
    String? farmId,
    ProgressCallback? onProgress,
  }) async {
    return 'asset_img_step7_abc';
  }

  @override
  Future<String> uploadAudio({
    required Uint8List bytes,
    String contentType = 'audio/wav',
    String? farmId,
    ProgressCallback? onProgress,
  }) async {
    return 'asset_audio_step7_abc';
  }
}

class MockStep7DiagnosisRepo extends DiagnosisRepository {
  DiagnoseResponse? nextResponse;

  @override
  Future<DiagnoseResponse> diagnose({
    required String farmId,
    required String imageAssetId,
    String? descriptionAssetId,
    String? descriptionText,
    String lang = 'mr-IN',
  }) async {
    return nextResponse ??
        const DiagnoseResponse(
          gate: GateDecision(
            outcome: 'advise',
            confidence: 0.88,
            thresholdApplied: 0.70,
            reasonCode: 'ABOVE_GATE',
            alternatives: [
              Prediction(label: 'blast', confidence: 0.88),
              Prediction(label: 'brown_spot', confidence: 0.08),
            ],
            isStub: false,
          ),
          problemId: 'p_step7_1',
          problemType: 'disease',
          diagnosis: DiagnosisDetail(
            label: 'blast',
            severity: 'early',
            confidence: 0.88,
          ),
          advisory: AdvisoryModel(
            possibleIssue: 'Early Blast (भातावरील करपा)',
            whatToCheck: 'Diamond-shaped lesions with grey centres',
            whatToAvoid: 'Do not top-dress nitrogen now. It accelerates spread.',
            ladder: [
              LadderRungModel(
                tier: 'cultural',
                action: 'Drain the field and dry for 48h.',
              ),
              LadderRungModel(
                tier: 'biological',
                action: 'Apply Pseudomonas fluorescens foliar spray.',
              ),
              LadderRungModel(
                tier: 'chemical',
                action: 'Tricyclazole 75 WP',
                dosage: '0.6 g per litre',
                phiDays: 30,
                reentryHours: 24,
              ),
            ],
          ),
        );
  }
}

class MockStep7DoubtDoctorRepo extends DoubtDoctorRepository {
  @override
  Future<DoubtDoctorAnswerResult> submitAnswer({
    required String problemId,
    required String cueId,
    required String answer,
  }) async {
    if (answer == 'yes') {
      return const DoubtDoctorAnswerResult(
        resolved: true,
        diagnosis: DiagnosisDetail(
          label: 'blast',
          severity: 'early',
          resolvedBy: 'field_observation',
        ),
        advisory: AdvisoryModel(
          possibleIssue: 'Confirmed Blast (करपा)',
          whatToCheck: 'Check surrounding hills for grey patches.',
          whatToAvoid: 'Do not top-dress nitrogen now.',
          ladder: [
            LadderRungModel(
              tier: 'cultural',
              action: 'Drain field for 48h.',
            ),
          ],
        ),
      );
    } else {
      // answer == 'unknown' or 'no' -> Inconclusive -> Auto-escalate
      return const DoubtDoctorAnswerResult(
        resolved: false,
        reason: 'answer_did_not_discriminate',
        escalation: EscalationModel(
          caseId: 'case_doubt_doc_esc_123',
          assignedTo: 'KVK Nashik Expert Panel',
          queuePosition: 2,
          etaMinutes: 30,
        ),
      );
    }
  }
}

class MockStep7AlertRepo extends AlertRepository {
  final List<AlertModel> activeAlerts = [
    const AlertModel(
      id: 'alert_step7_1',
      triggerType: 'weather',
      target: 'blast',
      riskLevel: 'high',
      reason: 'High humidity >90% for 3 days at tillering stage.',
      inspectionTasks: [
        'Inspect upper leaves on 10 plants across field.',
        'Take photo of any lesion with grey centre.',
      ],
      issuedAt: '2026-08-31T08:00:00Z',
    ),
  ];

  String? lastRespondedAlertId;
  String? lastRespondedOutcome;

  @override
  Future<AlertsResponse> getAlerts({
    required String farmId,
    String? cursor,
    int limit = 20,
  }) async {
    return AlertsResponse(alerts: activeAlerts);
  }

  @override
  Future<AlertRespondResponse> respondToAlert({
    required String alertId,
    required String outcome,
    String? imageAssetId,
  }) async {
    lastRespondedAlertId = alertId;
    lastRespondedOutcome = outcome;
    return AlertRespondResponse(
      alertId: alertId,
      outcome: outcome,
      diagnoseSuggested: outcome == 'found',
    );
  }
}

class MockStep7FollowUpRepo extends FollowUpRepository {
  final List<FollowUpModel> pendingFollowUps = [
    const FollowUpModel(
      id: 'followup_step7_1',
      problemId: 'p_step7_1',
      dueAt: '2026-08-31T12:00:00Z',
      target: 'BLAST_TREATMENT',
      question: 'How is the crop doing 3 days after draining the field?',
    ),
  ];

  String? lastFollowUpId;
  String? lastResponse;

  @override
  Future<PendingFollowUpsResponse> getPendingFollowUps(String farmId) async {
    return PendingFollowUpsResponse(followups: pendingFollowUps);
  }

  @override
  Future<FollowUpResultModel> respondToFollowUp({
    required String followUpId,
    required String response,
    String? imageAssetId,
  }) async {
    lastFollowUpId = followUpId;
    lastResponse = response;

    if (response == 'got_worse') {
      return const FollowUpResultModel(
        problemId: 'p_step7_1',
        severityChange: SeverityChangeModel(from: 'early', to: 'severe'),
        health: HealthModel(sentence: 'Worsening despite treatment.', trend: 'worsening'),
        escalated: true,
        caseId: 'case_followup_esc_999',
      );
    }

    return const FollowUpResultModel(
      problemId: 'p_step7_1',
      severityChange: SeverityChangeModel(from: 'early', to: 'early'),
      health: HealthModel(sentence: 'Crop improving.', trend: 'improving'),
      escalated: false,
    );
  }
}

class MockStep7FarmRepo extends FarmRepository {
  @override
  Future<FarmSummaryModel> getFarmSummary(String farmId) async {
    return FarmSummaryModel(
      farm: FarmModel(
        id: farmId,
        crop: 'paddy',
        variety: 'Indrayani',
        growthStage: 'tillering',
        region: 'Nashik',
      ),
      health: const HealthModel(
        sentence: 'One active problem under management.',
        trend: 'stable',
      ),
      openProblems: 1,
      pendingFollowups: 1,
      activeAlerts: 1,
    );
  }

  @override
  Future<FarmModel> createFarm({
    required String crop,
    String? variety,
    required String growthStage,
    required String region,
    required GeoPoint location,
  }) async {
    return FarmModel(
      id: 'f_new_step7_created',
      crop: crop,
      variety: variety,
      growthStage: growthStage,
      region: region,
      location: location,
    );
  }

  @override
  Future<FarmModel> getFarm(String farmId) => throw UnimplementedError();

  @override
  Future<FarmModel> updateFarm(String farmId, Map<String, dynamic> updates) =>
      throw UnimplementedError();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Step 7: Production Integration & State Transition Hardening', () {
    late MockInMemorySecureStorage mockSecureStorage;
    late TokenStorage tokenStorage;
    late MockStep7AuthRepo authRepo;
    late MockStep7AssetRepo assetRepo;
    late MockStep7DiagnosisRepo diagnosisRepo;
    late MockStep7DoubtDoctorRepo doubtDoctorRepo;
    late MockStep7AlertRepo alertRepo;
    late MockStep7FollowUpRepo followUpRepo;
    late MockStep7FarmRepo farmRepo;

    setUp(() {
      mockSecureStorage = MockInMemorySecureStorage();
      tokenStorage = TokenStorage(storage: mockSecureStorage);
      authRepo = MockStep7AuthRepo(tokenStorage: tokenStorage);
      assetRepo = MockStep7AssetRepo();
      diagnosisRepo = MockStep7DiagnosisRepo();
      doubtDoctorRepo = MockStep7DoubtDoctorRepo();
      alertRepo = MockStep7AlertRepo();
      followUpRepo = MockStep7FollowUpRepo();
      farmRepo = MockStep7FarmRepo();
    });

    Widget createTestApp(Widget child, [ProviderContainer? container]) {
      return UncontrolledProviderScope(
        container: container ??
            ProviderContainer(
              overrides: [
                tokenStorageProvider.overrideWithValue(tokenStorage),
                authRepositoryProvider.overrideWithValue(authRepo),
                assetRepositoryProvider.overrideWithValue(assetRepo),
                diagnosisRepositoryProvider.overrideWithValue(diagnosisRepo),
                doubtDoctorRepositoryProvider.overrideWithValue(doubtDoctorRepo),
                alertRepositoryProvider.overrideWithValue(alertRepo),
                followUpRepositoryProvider.overrideWithValue(followUpRepo),
                farmRepositoryProvider.overrideWithValue(farmRepo),
              ],
            ),
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: child,
        ),
      );
    }

    test('1. Authentication E2E State Transition (Request OTP -> Verify OTP -> Session Persistent)', () async {
      final container = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWithValue(tokenStorage),
          authRepositoryProvider.overrideWithValue(authRepo),
        ],
      );
      addTearDown(container.dispose);

      // Check initial unauthenticated state
      await container.read(authStateProvider.notifier).checkAuthStatus();
      expect(container.read(authStateProvider).isUnauthenticated, isTrue);

      // Step A: Request OTP
      final reqRes = await container.read(authStateProvider.notifier).requestOtp('+919876543210');
      expect(reqRes.requestId, 'req_otp_test_123');
      expect(reqRes.expiresIn, 300);

      // Step B: Verify OTP
      final verifyRes = await container.read(authStateProvider.notifier).verifyOtp(
        requestId: reqRes.requestId,
        otp: '123456',
      );
      expect(verifyRes.accessToken, 'valid_access_jwt');
      expect(verifyRes.user.id, 'u_farmer_step7');

      // Verify authenticated state & secure storage persistence
      expect(container.read(authStateProvider).isAuthenticated, isTrue);
      expect(await tokenStorage.getAccessToken(), 'valid_access_jwt');
      expect(await tokenStorage.hasValidSession(), isTrue);
    });

    test('2. Diagnosis & Presigned Upload State Transition (Image -> Upload -> Gated Outcome Advise)', () async {
      final container = ProviderContainer(
        overrides: [
          assetRepositoryProvider.overrideWithValue(assetRepo),
          diagnosisRepositoryProvider.overrideWithValue(diagnosisRepo),
        ],
      );
      addTearDown(container.dispose);

      final diagNotifier = container.read(diagnosisControllerProvider.notifier);
      final dummyLeafBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10]);

      // Set image in controller
      diagNotifier.setImage(dummyLeafBytes);
      expect(container.read(diagnosisControllerProvider).isPreviewing, isTrue);

      // Execute upload and gated diagnosis
      final response = await diagNotifier.submitDiagnosis(farmId: 'f_farm_1');
      expect(response, isNotNull);
      expect(response!.isAdvise, isTrue);
      expect(response.diagnosis?.label, 'blast');
      expect(response.advisory?.ladder.length, 3);
      expect(response.advisory?.ladder.last.tier, 'chemical'); // Invariant: Chemical last
      expect(container.read(diagnosisControllerProvider).isSuccess, isTrue);
    });

    testWidgets('3. Confidence Gate Routing & IPM Advisory Screen Verification', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWithValue(tokenStorage),
          authRepositoryProvider.overrideWithValue(authRepo),
          assetRepositoryProvider.overrideWithValue(assetRepo),
          diagnosisRepositoryProvider.overrideWithValue(diagnosisRepo),
          doubtDoctorRepositoryProvider.overrideWithValue(doubtDoctorRepo),
          alertRepositoryProvider.overrideWithValue(alertRepo),
          followUpRepositoryProvider.overrideWithValue(followUpRepo),
          farmRepositoryProvider.overrideWithValue(farmRepo),
        ],
      );
      addTearDown(container.dispose);

      const adviseResponse = DiagnoseResponse(
        gate: GateDecision(
          outcome: 'advise',
          confidence: 0.88,
          thresholdApplied: 0.70,
          reasonCode: 'ABOVE_GATE',
          alternatives: [Prediction(label: 'blast', confidence: 0.88)],
          isStub: false,
        ),
        problemId: 'p_step7_1',
        diagnosis: DiagnosisDetail(label: 'blast', severity: 'early', confidence: 0.88),
        advisory: AdvisoryModel(
          possibleIssue: 'Early Blast (भातावरील करपा)',
          whatToCheck: 'Diamond-shaped lesions on upper leaves',
          whatToAvoid: 'Do not top-dress nitrogen now. It accelerates spread.',
          ladder: [
            LadderRungModel(tier: 'cultural', action: 'Drain field for 48 hours.'),
            LadderRungModel(tier: 'chemical', action: 'Tricyclazole 75 WP', dosage: '0.6 g/L', phiDays: 30, reentryHours: 24),
          ],
        ),
      );

      await tester.pumpWidget(createTestApp(const AdvisoryResultScreen(response: adviseResponse), container));
      await tester.pumpAndSettle();

      // Verify IPM Order: What to avoid is rendered first and loud
      expect(find.text('WHAT TO AVOID FIRST (हे अजिबात करू नका):'), findsOneWidget);
      expect(find.text('Do not top-dress nitrogen now. It accelerates spread.'), findsOneWidget);
      expect(find.text('Cultural Action (मशागतीय / जैविक उपाय)'), findsOneWidget);

      // Chemical details collapsed by default
      expect(find.text('Chemical Action (रासायनिक फवारणी)'), findsOneWidget);
      await tester.tap(find.text('Chemical Action (रासायनिक फवारणी)'));
      await tester.pumpAndSettle();
      expect(find.text('Tricyclazole 75 WP'), findsOneWidget);
      expect(find.text('0.6 g/L'), findsOneWidget);
    });

    testWidgets('4. Doubt Doctor Resolution and Escalation on Inconclusive Observation', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWithValue(tokenStorage),
          authRepositoryProvider.overrideWithValue(authRepo),
          assetRepositoryProvider.overrideWithValue(assetRepo),
          diagnosisRepositoryProvider.overrideWithValue(diagnosisRepo),
          doubtDoctorRepositoryProvider.overrideWithValue(doubtDoctorRepo),
          alertRepositoryProvider.overrideWithValue(alertRepo),
          followUpRepositoryProvider.overrideWithValue(followUpRepo),
          farmRepositoryProvider.overrideWithValue(farmRepo),
        ],
      );
      addTearDown(container.dispose);

      const clarifyResponse = DiagnoseResponse(
        gate: GateDecision(
          outcome: 'clarify',
          confidence: 0.58,
          thresholdApplied: 0.15,
          reasonCode: 'AMBIGUOUS',
          alternatives: [
            Prediction(label: 'blast', confidence: 0.58),
            Prediction(label: 'brown_spot', confidence: 0.49),
          ],
          isStub: false,
        ),
        problemId: 'p_step7_ambiguous',
        clarification: ClarificationModel(
          cueId: 'cue_leaf_underside_4',
          question: 'Flip the leaf over. Do you see fuzzy grey growth?',
          questionLocalized: 'पान उलटून पहा. करडी बुरशी दिसते का?',
          candidates: [
            CandidateModel(label: 'blast', signature: 'Diamond-shaped spots with grey centres'),
            CandidateModel(label: 'brown_spot', signature: 'Round spots with yellow halo'),
          ],
          answers: ['yes', 'no', 'unknown'],
        ),
      );

      // Test Branch A: Farmer taps CAN'T TELL ('unknown') -> Auto-escalate
      await tester.pumpWidget(createTestApp(const DoubtDoctorScreen(response: clarifyResponse), container));
      await tester.pumpAndSettle();

      expect(find.text('पान उलटून पहा. करडी बुरशी दिसते का?'), findsOneWidget);
      expect(find.text("सांगता येत नाही (CAN'T TELL)"), findsOneWidget);

      // Tap CAN'T TELL
      await tester.tap(find.text("सांगता येत नाही (CAN'T TELL)"));
      await tester.pumpAndSettle();

      // Verifies navigation to EscalationStatusScreen
      expect(find.byType(EscalationStatusScreen), findsOneWidget);
      expect(find.text('case_doubt_doc_esc_123'), findsOneWidget);
      expect(find.text('KVK Nashik Expert Panel'), findsOneWidget);
    });

    testWidgets('5. Risk Alerts Surveillance (Fetch -> Respond -> Feedback Recorded)', (tester) async {
      final container = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWithValue(tokenStorage),
          authRepositoryProvider.overrideWithValue(authRepo),
          assetRepositoryProvider.overrideWithValue(assetRepo),
          diagnosisRepositoryProvider.overrideWithValue(diagnosisRepo),
          doubtDoctorRepositoryProvider.overrideWithValue(doubtDoctorRepo),
          alertRepositoryProvider.overrideWithValue(alertRepo),
          followUpRepositoryProvider.overrideWithValue(followUpRepo),
          farmRepositoryProvider.overrideWithValue(farmRepo),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestApp(const AlertsScreen(), container));
      await tester.pumpAndSettle();

      expect(find.text('BLAST'), findsOneWidget);
      expect(find.text('Inspect upper leaves on 10 plants across field.'), findsOneWidget);
      expect(find.text("I'LL CHECK (मी तपासतो)"), findsOneWidget);

      // Tap I'll check
      await tester.tap(find.text("I'LL CHECK (मी तपासतो)"));
      await tester.pumpAndSettle();

      expect(alertRepo.lastRespondedAlertId, 'alert_step7_1');
      expect(alertRepo.lastRespondedOutcome, 'found');
      expect(find.text('प्रतिसाद नोंदवला गेला आहे. शेताचे निरीक्षण केल्याबद्दल धन्यवाद!'), findsWidgets);
    });

    testWidgets('6. Closed-Loop Follow-Up State Transition (Fetch -> Got Worse -> Auto-Escalated)', (tester) async {
      final container = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWithValue(tokenStorage),
          authRepositoryProvider.overrideWithValue(authRepo),
          assetRepositoryProvider.overrideWithValue(assetRepo),
          diagnosisRepositoryProvider.overrideWithValue(diagnosisRepo),
          doubtDoctorRepositoryProvider.overrideWithValue(doubtDoctorRepo),
          alertRepositoryProvider.overrideWithValue(alertRepo),
          followUpRepositoryProvider.overrideWithValue(followUpRepo),
          farmRepositoryProvider.overrideWithValue(farmRepo),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestApp(const FollowupsScreen(), container));
      await tester.pumpAndSettle();

      expect(find.text('How is the crop doing 3 days after draining the field?'), findsOneWidget);
      expect(find.text('Got worse\n(बिघडले)'), findsOneWidget);

      // Tap Got Worse
      await tester.tap(find.text('Got worse\n(बिघडले)'));
      await tester.pumpAndSettle();

      expect(followUpRepo.lastFollowUpId, 'followup_step7_1');
      expect(followUpRepo.lastResponse, 'got_worse');
      expect(find.text('Auto-Escalated to Expert (Case ID: case_followup_esc_999)'), findsOneWidget);
      expect(find.text('Severity: early → severe'), findsOneWidget);
    });

    test('7. Multi-Farmer Session Isolation (Zero Cross-Account Leakage)', () async {
      final container = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWithValue(tokenStorage),
          authRepositoryProvider.overrideWithValue(authRepo),
          farmRepositoryProvider.overrideWithValue(farmRepo),
        ],
      );
      addTearDown(container.dispose);

      // Setup Farmer A
      await tokenStorage.saveTokens(accessToken: 'token_A', refreshToken: 'refresh_A');
      await tokenStorage.saveActiveFarmId('farm_A_101');
      container.read(activeFarmIdProvider.notifier).setActiveFarmId('farm_A_101');

      expect(await tokenStorage.getAccessToken(), 'token_A');
      expect(await tokenStorage.getActiveFarmId(), 'farm_A_101');

      // Logout Farmer A
      await container.read(authStateProvider.notifier).logout();

      // Confirm complete purge
      expect(await tokenStorage.getAccessToken(), isNull);
      expect(await tokenStorage.getActiveFarmId(), isEmpty);
      expect(container.read(activeFarmIdProvider), isNull);

      // Setup Farmer B
      await tokenStorage.saveTokens(accessToken: 'token_B', refreshToken: 'refresh_B');
      await tokenStorage.saveActiveFarmId('farm_B_999');
      container.read(activeFarmIdProvider.notifier).setActiveFarmId('farm_B_999');

      expect(await tokenStorage.getAccessToken(), 'token_B');
      expect(await tokenStorage.getActiveFarmId(), 'farm_B_999');
      expect(container.read(activeFarmIdProvider), 'farm_B_999');
    });
  });
}
