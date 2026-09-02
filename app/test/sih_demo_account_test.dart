import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bhoomi/main.dart';
import 'package:bhoomi/core/storage/secure_storage.dart';
import 'package:bhoomi/core/storage/token_storage.dart';
import 'package:bhoomi/providers/storage_providers.dart';
import 'package:bhoomi/features/onboarding/presentation/phone_auth_screen.dart';
import 'package:bhoomi/features/home/presentation/home_screen.dart';
import 'package:bhoomi/models/auth_models.dart';
import 'package:bhoomi/models/farm_models.dart';
import 'package:bhoomi/models/alert_models.dart';
import 'package:bhoomi/models/timeline_models.dart';
import 'package:bhoomi/models/referral_models.dart';
import 'package:bhoomi/models/followup_models.dart';
import 'package:bhoomi/repositories/auth_repository.dart';
import 'package:bhoomi/repositories/farm_repository.dart';
import 'package:bhoomi/repositories/alert_repository.dart';
import 'package:bhoomi/repositories/timeline_repository.dart';
import 'package:bhoomi/repositories/referral_repository.dart';
import 'package:bhoomi/repositories/followup_repository.dart';
import 'package:bhoomi/providers/repository_providers.dart';
import 'package:bhoomi/widgets/language_selector_button.dart';

class MockDemoSecureStorage extends SecureStorage {
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
}

class FakeDemoAuthRepo extends AuthRepository {
  bool isAuthed = false;
  UserModel? currentUser;

  @override
  Future<OtpRequestResponse> requestOtp({required String phone}) async {
    return const OtpRequestResponse(requestId: 'req_demo_01', expiresIn: 300);
  }

  @override
  Future<OtpVerifyResponse> verifyOtp({required String requestId, required String otp}) async {
    if (otp == '123456') {
      final user = const UserModel(id: 'u_real_01', phone: '+919876543210', role: 'farmer');
      isAuthed = true;
      currentUser = user;
      return OtpVerifyResponse(accessToken: 'real_access_token', refreshToken: 'real_refresh', user: user);
    }
    throw Exception('Invalid OTP');
  }

  @override
  Future<OtpVerifyResponse> loginAsDemo({String demoCode = 'SIH2026'}) async {
    if (demoCode != 'SIH2026') {
      throw Exception('Invalid demo code');
    }
    const demoUser = UserModel(id: 'u_demo_01', name: 'Ramesh Patil', phone: '+919999999999', role: 'farmer');
    isAuthed = true;
    currentUser = demoUser;
    return const OtpVerifyResponse(
      accessToken: 'demo_access_token',
      refreshToken: 'demo_refresh_token',
      user: demoUser,
    );
  }

  @override
  Future<void> logout() async {
    isAuthed = false;
    currentUser = null;
  }

  @override
  Future<bool> isAuthenticated() async => isAuthed;

  @override
  Future<UserModel?> getCurrentUser() async => currentUser;
}

class FakeDemoFarmRepo extends FarmRepository {
  @override
  Future<FarmSummaryModel> getFarmSummary(String farmId) async {
    return const FarmSummaryModel(
      farm: FarmModel(
        id: 'f_demo_01',
        crop: 'paddy',
        variety: 'Indrayani',
        growthStage: 'tillering',
        region: 'Nashik',
      ),
      health: HealthModel(sentence: 'Field health is stable. Kharif paddy active.', trend: 'stable'),
      activeProblemsCount: 1,
      pendingFollowUpsCount: 1,
      activeAlertsCount: 1,
    );
  }

  @override
  Future<FarmModel> createFarm({required String crop, String? variety, required String growthStage, required String region, required GeoPoint location}) =>
      throw UnimplementedError();

  @override
  Future<FarmModel> getFarm(String farmId) async => const FarmModel(
        id: 'f_demo_01',
        crop: 'paddy',
        variety: 'Indrayani',
        growthStage: 'tillering',
        region: 'Nashik',
      );

  @override
  Future<FarmModel> updateFarm(String farmId, Map<String, dynamic> updates) => throw UnimplementedError();
}

class FakeDemoAlertRepo extends AlertRepository {
  @override
  Future<AlertsResponse> getAlerts({required String farmId, int limit = 20, String? cursor}) async {
    return const AlertsResponse(
      alerts: [
        AlertModel(
          id: 'alt_demo_01',
          triggerType: 'weather',
          target: 'blast',
          riskLevel: 'moderate',
          reason: 'paddy_blast_favourability',
          inspectionTasks: ['Inspect upper leaves for blast spots'],
          issuedAt: '2026-09-01T08:00:00Z',
        ),
      ],
    );
  }

  @override
  Future<AlertRespondResponse> respondToAlert({required String alertId, required String outcome, String? imageAssetId}) async {
    return const AlertRespondResponse(status: 'recorded', alertId: 'alt_demo_01', recordedAt: '2026-09-02');
  }
}

class FakeDemoTimelineRepo extends TimelineRepository {
  @override
  Future<TimelineResponse> getTimeline({required String farmId, int limit = 20, String? cursor}) async {
    return const TimelineResponse(
      events: [
        TimelineEventModel(
          id: 'tl_demo_01',
          type: 'advisory',
          title: 'IPM Advisory Issued',
          description: 'Cultural aeration recommended.',
          timestamp: '2026-08-30T10:30:00Z',
        ),
      ],
    );
  }
}

class FakeDemoReferralRepo extends ReferralRepository {
  @override
  Future<ReferralsResponse> getReferrals(String farmId) async {
    return ReferralsResponse(
      referrals: const [
        ReferralModel(
          kind: 'kvk',
          name: 'KVK Nashik',
          phone: '0253-2231265',
          address: 'Nashik',
        ),
      ],
    );
  }
}

class FakeDemoFollowUpRepo extends FollowUpRepository {
  @override
  Future<PendingFollowUpsResponse> getPendingFollowUps(String farmId) async {
    return const PendingFollowUpsResponse(
      followups: [
        FollowUpModel(
          id: 'fu_demo_01',
          problemId: 'p_demo_01',
          dueAt: '2026-09-02',
          target: 'Paddy Blast',
          question: 'Check leaf lesions',
        ),
      ],
    );
  }

  @override
  Future<FollowUpResultModel> respondToFollowUp({required String followUpId, required String response, String? imageAssetId}) async {
    return const FollowUpResultModel(
      problemId: 'p_demo_01',
      status: 'completed',
    );
  }
}

List<Override> _getDemoOverrides(MockDemoSecureStorage storage, FakeDemoAuthRepo authRepo) {
  return [
    secureStorageProvider.overrideWithValue(storage),
    tokenStorageProvider.overrideWithValue(TokenStorage(storage: storage)),
    authRepositoryProvider.overrideWithValue(authRepo),
    farmRepositoryProvider.overrideWithValue(FakeDemoFarmRepo()),
    alertRepositoryProvider.overrideWithValue(FakeDemoAlertRepo()),
    timelineRepositoryProvider.overrideWithValue(FakeDemoTimelineRepo()),
    referralRepositoryProvider.overrideWithValue(FakeDemoReferralRepo()),
    followUpRepositoryProvider.overrideWithValue(FakeDemoFollowUpRepo()),
  ];
}

void main() {
  group('SIH Demo Account & Demo Mode Tests', () {
    late MockDemoSecureStorage storage;
    late FakeDemoAuthRepo authRepo;

    setUp(() {
      storage = MockDemoSecureStorage();
      authRepo = FakeDemoAuthRepo();
    });

    testWidgets('Demo Account button is displayed on PhoneAuthScreen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: _getDemoOverrides(storage, authRepo),
          child: const BhoomiApp(homeOverride: PhoneAuthScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('🌾 डेमो खाते वापरून पहा'), findsOneWidget);
      expect(find.text('OTP पाठवा'), findsOneWidget);
    });

    testWidgets('Tapping Try Demo Account opens the Bhoomi Demo confirmation modal', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: _getDemoOverrides(storage, authRepo),
          child: const BhoomiApp(homeOverride: PhoneAuthScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Tap demo button
      await tester.tap(find.text('🌾 डेमो खाते वापरून पहा'));
      await tester.pumpAndSettle();

      // Modal content
      expect(find.text('🌾 भूमी डेमो'), findsOneWidget);
      expect(find.text('शेतकरी: रमेश पाटील'), findsOneWidget);
      expect(find.text('शेत: डेमो भात शेत (Demo Paddy Farm)'), findsOneWidget);
      expect(find.text('स्थान: नाशिक, महाराष्ट्र'), findsOneWidget);
      expect(find.text('डेमो मध्ये प्रवेश करा'), findsOneWidget);
      expect(find.text('रद्द करा'), findsOneWidget);
    });

    testWidgets('Entering Demo Account authenticates and loads pre-populated Demo Farm dashboard',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: _getDemoOverrides(storage, authRepo),
          child: const BhoomiApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap demo button and enter demo
      await tester.tap(find.text('🌾 डेमो खाते वापरून पहा'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('डेमो मध्ये प्रवेश करा'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Verifies authentication state and user identity
      expect(authRepo.isAuthed, isTrue);
      expect(authRepo.currentUser?.name, 'Ramesh Patil');
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('Demo mode respects global language selection (Marathi, Hindi, English)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: _getDemoOverrides(storage, authRepo),
          child: const BhoomiApp(homeOverride: PhoneAuthScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Switch language to English
      await tester.tap(find.byType(LanguageSelectorButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      // English button text
      expect(find.text('🌾 Try Demo Account'), findsOneWidget);

      // Open modal in English
      await tester.tap(find.text('🌾 Try Demo Account'));
      await tester.pumpAndSettle();

      expect(find.text('🌾 Bhoomi Demo'), findsOneWidget);
      expect(find.text('Farmer: Ramesh Patil'), findsOneWidget);
      expect(find.text('Farm: Demo Paddy Farm'), findsOneWidget);
      expect(find.text('Location: Nashik, Maharashtra'), findsOneWidget);
      expect(find.text('Enter Demo'), findsOneWidget);
    });

    testWidgets('Normal OTP authentication flow continues to work independently without bypass',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: _getDemoOverrides(storage, authRepo),
          child: const BhoomiApp(homeOverride: PhoneAuthScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Enter a regular 10-digit number
      await tester.enterText(find.byType(TextField), '9876543210');
      await tester.pump();

      // Tap Send OTP
      await tester.tap(find.text('OTP पाठवा'));
      await tester.pumpAndSettle();

      // Verifies it navigated to OtpVerifyScreen for normal OTP flow
      expect(find.text('नंबर पडताळणी करा'), findsOneWidget);
    });
  });
}
