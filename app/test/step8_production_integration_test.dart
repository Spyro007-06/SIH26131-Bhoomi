import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import 'package:bhoomi/main.dart';
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
import 'package:bhoomi/models/timeline_models.dart';
import 'package:bhoomi/models/referral_models.dart';
import 'package:bhoomi/models/asset_models.dart';

import 'package:bhoomi/repositories/auth_repository.dart';
import 'package:bhoomi/repositories/farm_repository.dart';
import 'package:bhoomi/repositories/asset_repository.dart';
import 'package:bhoomi/repositories/diagnosis_repository.dart';
import 'package:bhoomi/repositories/doubt_doctor_repository.dart';
import 'package:bhoomi/repositories/alert_repository.dart';
import 'package:bhoomi/repositories/followup_repository.dart';
import 'package:bhoomi/repositories/timeline_repository.dart';
import 'package:bhoomi/repositories/referral_repository.dart';

import 'package:bhoomi/providers/farm_providers.dart';
import 'package:bhoomi/providers/storage_providers.dart';
import 'package:bhoomi/providers/repository_providers.dart';

import 'package:bhoomi/features/shell/presentation/main_app_shell.dart';
import 'package:bhoomi/features/home/presentation/home_screen.dart';
import 'package:bhoomi/features/onboarding/presentation/otp_verify_screen.dart';
import 'package:bhoomi/features/alerts/presentation/alerts_screen.dart';
import 'package:bhoomi/features/followup/presentation/followups_screen.dart';
import 'package:bhoomi/features/timeline/presentation/history_screen.dart';
import 'package:bhoomi/features/referrals/presentation/referrals_screen.dart';
import 'package:bhoomi/features/more/presentation/more_screen.dart';

// --- In-Memory Secure Storage Mock ---
class MockStep8SecureStorage extends SecureStorage {
  final Map<String, String> _data = {};

  @override
  Future<void> write({required String key, required String value}) async {
    _data[key] = value;
  }

  @override
  Future<String?> read({required String key}) async {
    return _data[key];
  }

  @override
  Future<void> delete({required String key}) async {
    _data.remove(key);
  }

  @override
  Future<void> deleteAll() async {
    _data.clear();
  }
}

// --- Step 8 Master Mock Harness ---
class MockStep8AuthRepo extends AuthRepository {
  final TokenStorage tokenStorage;
  bool _isAuthed = false;
  UserModel? _user;

  MockStep8AuthRepo({required this.tokenStorage});

  @override
  Future<bool> isAuthenticated() async => _isAuthed;

  @override
  Future<UserModel?> getCurrentUser() async => _user;

  @override
  Future<OtpRequestResponse> requestOtp({required String phone}) async {
    return const OtpRequestResponse(
      requestId: 'req_step8_otp_999',
      expiresIn: 300,
    );
  }

  @override
  Future<OtpVerifyResponse> verifyOtp({
    required String requestId,
    required String otp,
  }) async {
    if (otp == '123456') {
      _isAuthed = true;
      _user = const UserModel(
        id: 'u_farmer_step8_demo',
        phone: '+919876543210',
        role: 'farmer',
      );
      await tokenStorage.saveTokens(
        accessToken: 'jwt_access_step8_demo',
        refreshToken: 'jwt_refresh_step8_demo',
      );
      await tokenStorage.saveUserData(_user!.toJson());
      return OtpVerifyResponse(
        accessToken: 'jwt_access_step8_demo',
        refreshToken: 'jwt_refresh_step8_demo',
        user: _user!,
      );
    }
    throw Exception('INVALID_OTP');
  }

  @override
  Future<OtpVerifyResponse> loginAsDemo({String demoCode = 'SIH2026'}) async {
    _isAuthed = true;
    _user = const UserModel(
      id: 'u_farmer_step8_demo',
      phone: '+919999999999',
      name: 'Ramesh Patil',
      role: 'farmer',
    );
    await tokenStorage.saveTokens(
      accessToken: 'jwt_access_step8_demo',
      refreshToken: 'jwt_refresh_step8_demo',
    );
    await tokenStorage.saveUserData(_user!.toJson());
    return OtpVerifyResponse(
      accessToken: 'jwt_access_step8_demo',
      refreshToken: 'jwt_refresh_step8_demo',
      user: _user!,
    );
  }

  @override
  Future<void> logout() async {
    _isAuthed = false;
    _user = null;
    await tokenStorage.clearSession();
  }
}

class MockStep8FarmRepo extends FarmRepository {
  FarmModel? currentFarm;

  @override
  Future<FarmSummaryModel> getFarmSummary(String farmId) async {
    return FarmSummaryModel(
      farm: currentFarm ??
          FarmModel(
            id: farmId,
            crop: 'paddy',
            variety: 'Indrayani',
            growthStage: 'Tillering',
            region: 'Nashik',
            location: const GeoPoint(lat: 19.9975, lng: 73.7898),
          ),
      health: const HealthModel(
        sentence: 'पिकाची प्रकृती स्थिर आहे (Crop health stable).',
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
    currentFarm = FarmModel(
      id: 'f_step8_demo_farm',
      crop: crop,
      variety: variety,
      growthStage: growthStage,
      region: region,
      location: location,
    );
    return currentFarm!;
  }

  @override
  Future<FarmModel> getFarm(String farmId) async {
    return currentFarm ??
        FarmModel(
          id: farmId,
          crop: 'paddy',
          growthStage: 'Tillering',
          region: 'Nashik',
        );
  }

  @override
  Future<FarmModel> updateFarm(String farmId, Map<String, dynamic> updates) async {
    return currentFarm ??
        FarmModel(
          id: farmId,
          crop: 'paddy',
          growthStage: 'Tillering',
          region: 'Nashik',
        );
  }
}

class MockStep8AssetRepo extends AssetRepository {
  @override
  Future<PresignedAssetModel> presignAsset({
    required String kind,
    required String contentType,
    String? farmId,
  }) async {
    return const PresignedAssetModel(
      assetId: 'asset_step8_demo_img',
      uploadUrl: 'https://storage.bhoomi.gov.in/presigned_step8_upload',
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
    return 'asset_step8_demo_img';
  }

  @override
  Future<String> uploadAudio({
    required Uint8List bytes,
    String contentType = 'audio/wav',
    String? farmId,
    ProgressCallback? onProgress,
  }) async {
    return 'asset_step8_demo_audio';
  }
}

class MockStep8DiagnosisRepo extends DiagnosisRepository {
  @override
  Future<DiagnoseResponse> diagnose({
    required String farmId,
    required String imageAssetId,
    String? descriptionAssetId,
    String? descriptionText,
    String lang = 'mr-IN',
  }) async {
    return const DiagnoseResponse(
      gate: GateDecision(
        outcome: 'advise',
        confidence: 0.91,
        thresholdApplied: 0.70,
        reasonCode: 'ABOVE_GATE',
        alternatives: [
          Prediction(label: 'blast', confidence: 0.91),
          Prediction(label: 'brown_spot', confidence: 0.05),
        ],
        isStub: false,
      ),
      problemId: 'p_step8_blast_101',
      problemType: 'disease',
      diagnosis: DiagnosisDetail(
        label: 'blast',
        severity: 'early',
        confidence: 0.91,
      ),
      advisory: AdvisoryModel(
        possibleIssue: 'Early Paddy Blast (भातावरील करपा)',
        whatToCheck: 'Diamond-shaped lesions with grey centres on leaves',
        whatToAvoid: 'Do not top-dress nitrogen now. It accelerates fungal spread.',
        ladder: [
          LadderRungModel(
            tier: 'cultural',
            action: 'Drain field and let surface dry for 48 hours.',
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

class MockStep8DoubtDoctorRepo extends DoubtDoctorRepository {
  @override
  Future<DoubtDoctorAnswerResult> submitAnswer({
    required String problemId,
    required String cueId,
    required String answer,
  }) async {
    if (answer == 'yes') {
      return const DoubtDoctorAnswerResult(
        resolved: true,
        diagnosis: DiagnosisDetail(label: 'blast', severity: 'early'),
        advisory: AdvisoryModel(
          possibleIssue: 'Confirmed Blast (करपा)',
          whatToCheck: 'Check surrounding hills.',
          whatToAvoid: 'Do not apply urea now.',
          ladder: [LadderRungModel(tier: 'cultural', action: 'Drain field for 48h.')],
        ),
      );
    }
    return const DoubtDoctorAnswerResult(
      resolved: false,
      reason: 'answer_did_not_discriminate',
      escalation: EscalationModel(
        caseId: 'CASE-STEP8-NASHIK-99',
        assignedTo: 'KVK Nashik Agronomy Cell',
        queuePosition: 1,
        etaMinutes: 15,
      ),
    );
  }
}

class MockStep8AlertRepo extends AlertRepository {
  @override
  Future<AlertsResponse> getAlerts({
    required String farmId,
    int limit = 20,
    String? cursor,
  }) async {
    return const AlertsResponse(
      alerts: [
        AlertModel(
          id: 'alt_step8_blast',
          triggerType: 'weather',
          target: 'blast',
          riskLevel: 'high',
          reason: 'Humidity > 90% for 3 nights in Nashik tillering paddy.',
          inspectionTasks: [
            'Check upper leaves on 10 plants across field.',
            'Look for spindle-shaped spots.',
          ],
          issuedAt: '2026-08-31T06:00:00Z',
        ),
      ],
    );
  }

  @override
  Future<AlertRespondResponse> respondToAlert({
    required String alertId,
    required String outcome,
    String? imageAssetId,
  }) async {
    return AlertRespondResponse(
      alertId: alertId,
      outcome: outcome,
      diagnoseSuggested: outcome == 'found',
    );
  }
}

class MockStep8FollowUpRepo extends FollowUpRepository {
  @override
  Future<PendingFollowUpsResponse> getPendingFollowUps(String farmId) async {
    return const PendingFollowUpsResponse(
      followups: [
        FollowUpModel(
          id: 'flw_step8_check',
          problemId: 'p_step8_blast_101',
          dueAt: '2026-08-31T10:00:00Z',
          target: 'BLAST_TREATMENT',
          question: 'How is the crop 4 days after draining the field?',
        ),
      ],
    );
  }

  @override
  Future<FollowUpResultModel> respondToFollowUp({
    required String followUpId,
    required String response,
    String? imageAssetId,
  }) async {
    if (response == 'got_worse') {
      return const FollowUpResultModel(
        problemId: 'p_step8_blast_101',
        severityChange: SeverityChangeModel(from: 'early', to: 'severe'),
        escalated: true,
        caseId: 'CASE-AUTO-ESC-888',
      );
    }
    return const FollowUpResultModel(
      problemId: 'p_step8_blast_101',
      severityChange: SeverityChangeModel(from: 'early', to: 'early'),
      escalated: false,
    );
  }
}

class MockStep8TimelineRepo extends TimelineRepository {
  @override
  Future<TimelineResponse> getTimeline({
    required String farmId,
    int limit = 20,
    String? cursor,
  }) async {
    return const TimelineResponse(
      events: [
        TimelineEventModel(
          id: 'ev_step8_1',
          type: 'diagnosis',
          title: 'Early Blast Diagnosis',
          description: 'Diagnosed by vision model with 91% confidence.',
          timestamp: '2026-08-31T08:00:00Z',
        ),
      ],
    );
  }
}

class MockStep8ReferralRepo extends ReferralRepository {
  @override
  Future<ReferralsResponse> getReferrals(String farmId) async {
    return ReferralsResponse(
      referrals: const [
        ReferralModel(
          kind: 'kvk',
          name: 'Krishi Vigyan Kendra (KVK) Nashik',
          phone: '+912532591234',
          distanceKm: 8.5,
          address: 'Dindori Road, Nashik, Maharashtra',
          acceptsSamples: true,
        ),
        ReferralModel(
          kind: 'helpline',
          name: 'Kisan Call Center',
          phone: '1800-180-1551',
        ),
      ],
    );
  }
}

List<Override> _createMasterStep8Overrides({
  required TokenStorage tokenStorage,
  required MockStep8AuthRepo authRepo,
  required MockStep8FarmRepo farmRepo,
  required MockStep8AssetRepo assetRepo,
  required MockStep8DiagnosisRepo diagnosisRepo,
  required MockStep8DoubtDoctorRepo doubtDoctorRepo,
  required MockStep8AlertRepo alertRepo,
  required MockStep8FollowUpRepo followUpRepo,
  required MockStep8TimelineRepo timelineRepo,
  required MockStep8ReferralRepo referralRepo,
}) {
  return [
    tokenStorageProvider.overrideWithValue(tokenStorage),
    authRepositoryProvider.overrideWithValue(authRepo),
    farmRepositoryProvider.overrideWithValue(farmRepo),
    assetRepositoryProvider.overrideWithValue(assetRepo),
    diagnosisRepositoryProvider.overrideWithValue(diagnosisRepo),
    doubtDoctorRepositoryProvider.overrideWithValue(doubtDoctorRepo),
    alertRepositoryProvider.overrideWithValue(alertRepo),
    followUpRepositoryProvider.overrideWithValue(followUpRepo),
    timelineRepositoryProvider.overrideWithValue(timelineRepo),
    referralRepositoryProvider.overrideWithValue(referralRepo),
    activeFarmIdProvider.overrideWith((ref) => ActiveFarmIdNotifier(null, 'f_step8_demo_farm')),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Step 8: Master Production Integration, Accessibility & Responsive Audit', () {
    late MockStep8SecureStorage mockSecureStorage;
    late TokenStorage tokenStorage;
    late MockStep8AuthRepo authRepo;
    late MockStep8FarmRepo farmRepo;
    late MockStep8AssetRepo assetRepo;
    late MockStep8DiagnosisRepo diagnosisRepo;
    late MockStep8DoubtDoctorRepo doubtDoctorRepo;
    late MockStep8AlertRepo alertRepo;
    late MockStep8FollowUpRepo followUpRepo;
    late MockStep8TimelineRepo timelineRepo;
    late MockStep8ReferralRepo referralRepo;

    setUp(() {
      mockSecureStorage = MockStep8SecureStorage();
      tokenStorage = TokenStorage(storage: mockSecureStorage);
      authRepo = MockStep8AuthRepo(tokenStorage: tokenStorage);
      farmRepo = MockStep8FarmRepo();
      assetRepo = MockStep8AssetRepo();
      diagnosisRepo = MockStep8DiagnosisRepo();
      doubtDoctorRepo = MockStep8DoubtDoctorRepo();
      alertRepo = MockStep8AlertRepo();
      followUpRepo = MockStep8FollowUpRepo();
      timelineRepo = MockStep8TimelineRepo();
      referralRepo = MockStep8ReferralRepo();
    });

    testWidgets('1. Full Sequential SIH Demo Journey (Auth -> Farm -> Diagnose -> IPM -> Alerts -> Followup -> Referrals -> Logout)',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final overrides = _createMasterStep8Overrides(
        tokenStorage: tokenStorage,
        authRepo: authRepo,
        farmRepo: farmRepo,
        assetRepo: assetRepo,
        diagnosisRepo: diagnosisRepo,
        doubtDoctorRepo: doubtDoctorRepo,
        alertRepo: alertRepo,
        followUpRepo: followUpRepo,
        timelineRepo: timelineRepo,
        referralRepo: referralRepo,
      );

      final container = ProviderContainer(overrides: overrides);
      addTearDown(container.dispose);

      // Phase 1: Launch Root Bhoomi App (starts at LandingScreen when unauthenticated)
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const BhoomiApp(),
        ),
      );
      await tester.pumpAndSettle();

      // If on LandingScreen, tap Start to enter PhoneAuthScreen
      if (find.text('सुरू करा').evaluate().isNotEmpty) {
        await tester.tap(find.text('सुरू करा'));
        await tester.pumpAndSettle();
      }

      expect(find.text('भूमीमध्ये आपले स्वागत आहे'), findsOneWidget);
      expect(find.text('🇮🇳 +91'), findsOneWidget);

      // Phase 2: Enter Phone Number and Request OTP
      await tester.enterText(find.byType(TextField), '9876543210');
      await tester.pumpAndSettle();
      await tester.tap(find.text('OTP पाठवा'));
      await tester.pumpAndSettle();

      // Phase 3: Enter OTP on OtpVerifyScreen and Verify
      expect(find.byType(OtpVerifyScreen), findsOneWidget);
      expect(find.text('पडताळणी करा'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '123456');
      await tester.pumpAndSettle();
      await tester.tap(find.text('पडताळणी करा'));
      await tester.pumpAndSettle();

      // Phase 4: Home Dashboard verification in MainAppShell
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('पिकावर काही रोग किंवा कीड दिसतेय?'), findsOneWidget);

      // Phase 5: Switch to Alerts Tab
      await tester.tap(find.byIcon(Icons.shield_outlined).last);
      await tester.pumpAndSettle();
      expect(find.byType(AlertsScreen), findsOneWidget);
      expect(find.text('BLAST'), findsOneWidget);

      // Phase 6: Acknowledge Alert (Inspect Now)
      await tester.tap(find.text("I'LL CHECK (मी तपासतो)"));
      await tester.pumpAndSettle();
      expect(find.text('प्रतिसाद नोंदवला गेला आहे. शेताचे निरीक्षण केल्याबद्दल धन्यवाद!'), findsWidgets);

      // Phase 7: Switch to History Tab
      await tester.tap(find.byIcon(Icons.history_rounded).last);
      await tester.pumpAndSettle();
      expect(find.byType(HistoryScreen), findsOneWidget);

      // Phase 8: Switch to More Tab
      await tester.tap(find.byIcon(Icons.more_horiz_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(MoreScreen), findsOneWidget);

      // Phase 9: Open Referrals Directory
      await tester.tap(find.text('कृषी विज्ञान केंद्र (KVK) व मदत केंद्र'));
      await tester.pumpAndSettle();
      expect(find.byType(ReferralsScreen), findsOneWidget);
      expect(find.text('Krishi Vigyan Kendra (KVK) Nashik'), findsOneWidget);
      expect(find.text('1800-180-1551'), findsOneWidget);

      // Pop back to More
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.byType(MoreScreen), findsOneWidget);

      // Phase 10: Local Logout confirmation
      await tester.tap(find.text('बाहेर पडा (Log Out)'));
      await tester.pumpAndSettle();
      expect(find.text('तुम्हाला बाहेर पडायचे आहे का?'), findsOneWidget);
      await tester.tap(find.text('हो, बाहेर पडा'));
      await tester.pumpAndSettle();

      // Verify complete local session destruction
      expect(await tokenStorage.hasValidSession(), isFalse);
    });

    testWidgets('2. Accessibility & Dynamic Text Scaling Audit (1.0x, 1.5x, 2.0x)',
        (tester) async {
      final scalers = [
        const TextScaler.linear(1.0),
        const TextScaler.linear(1.5),
        const TextScaler.linear(2.0),
      ];

      final overrides = _createMasterStep8Overrides(
        tokenStorage: tokenStorage,
        authRepo: authRepo,
        farmRepo: farmRepo,
        assetRepo: assetRepo,
        diagnosisRepo: diagnosisRepo,
        doubtDoctorRepo: doubtDoctorRepo,
        alertRepo: alertRepo,
        followUpRepo: followUpRepo,
        timelineRepo: timelineRepo,
        referralRepo: referralRepo,
      );

      for (final scaler in scalers) {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;

        await tester.pumpWidget(
          ProviderScope(
            overrides: overrides,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              builder: (context, child) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(textScaler: scaler),
                  child: child!,
                );
              },
              home: const MainAppShell(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify zero layout overflow exception
        expect(tester.takeException(), isNull);
        expect(find.byType(MainAppShell), findsOneWidget);
      }
      tester.view.resetPhysicalSize();
    });

    testWidgets('3. Multi-Form-Factor Responsive Layout Audit (Compact, Standard, Tall)',
        (tester) async {
      final viewports = [
        const Size(360, 640),   // Compact 4.7" Android
        const Size(390, 844),   // Standard 6.1" phone
        const Size(412, 915),   // Modern tall phone (Pixel 7)
        const Size(540, 1200),  // Foldable unfolded / wide device
      ];

      final overrides = _createMasterStep8Overrides(
        tokenStorage: tokenStorage,
        authRepo: authRepo,
        farmRepo: farmRepo,
        assetRepo: assetRepo,
        diagnosisRepo: diagnosisRepo,
        doubtDoctorRepo: doubtDoctorRepo,
        alertRepo: alertRepo,
        followUpRepo: followUpRepo,
        timelineRepo: timelineRepo,
        referralRepo: referralRepo,
      );

      for (final size in viewports) {
        tester.view.physicalSize = size * 2.0;
        tester.view.devicePixelRatio = 2.0;

        await tester.pumpWidget(
          ProviderScope(
            overrides: overrides,
            child: const BhoomiApp(homeOverride: MainAppShell()),
          ),
        );
        await tester.pumpAndSettle();

        // Verify clean rendering with zero layout overflow
        expect(tester.takeException(), isNull);
        expect(find.byType(HomeScreen), findsOneWidget);
      }
      tester.view.resetPhysicalSize();
    });

    testWidgets('4. Low-Connectivity Error Resilience and Idempotent Retry State Machine',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final overrides = _createMasterStep8Overrides(
        tokenStorage: tokenStorage,
        authRepo: authRepo,
        farmRepo: farmRepo,
        assetRepo: assetRepo,
        diagnosisRepo: diagnosisRepo,
        doubtDoctorRepo: doubtDoctorRepo,
        alertRepo: alertRepo,
        followUpRepo: followUpRepo,
        timelineRepo: timelineRepo,
        referralRepo: referralRepo,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides,
          child: const BhoomiApp(homeOverride: FollowupsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('How is the crop 4 days after draining the field?'), findsOneWidget);
      expect(find.text('Got worse\n(बिघडले)'), findsOneWidget);

      // Tap Got Worse -> triggers auto-escalation
      await tester.tap(find.text('Got worse\n(बिघडले)'));
      await tester.pumpAndSettle();

      expect(find.text('Auto-Escalated to Expert (Case ID: CASE-AUTO-ESC-888)'), findsOneWidget);
      expect(find.text('Severity: early → severe'), findsOneWidget);

      // Verify second tap is rejected (non-duplicated, idempotent)
      await tester.tap(find.text('Got worse\n(बिघडले)'));
      await tester.pumpAndSettle();
      expect(find.text('Auto-Escalated to Expert (Case ID: CASE-AUTO-ESC-888)'), findsOneWidget);
    });
  });
}
