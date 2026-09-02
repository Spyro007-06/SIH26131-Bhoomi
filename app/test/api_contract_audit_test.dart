import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bhoomi/core/constants/api_endpoints.dart';
import 'package:bhoomi/core/constants/app_constants.dart';
import 'package:bhoomi/core/network/api_client.dart';
import 'package:bhoomi/core/network/api_config.dart';
import 'package:bhoomi/core/storage/token_storage.dart';
import 'package:bhoomi/core/storage/secure_storage.dart';
import 'package:bhoomi/repositories/auth_repository.dart';
import 'package:bhoomi/providers/auth_providers.dart';
import 'package:bhoomi/providers/repository_providers.dart';
import 'package:bhoomi/models/diagnosis_models.dart';

class InMemorySecureStorage extends SecureStorage {
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

  @override
  Future<bool> containsKey({required String key}) async {
    return _data.containsKey(key);
  }
}

class RequestCountingApiClient extends ApiClient {
  int totalRequestsMade = 0;

  RequestCountingApiClient({required TokenStorage tokenStorage})
      : super(
          config: const ApiConfig(),
          tokenStorage: tokenStorage,
        );

  @override
  Future<dynamic> get(String path,
      {Map<String, dynamic>? queryParameters, Options? options}) async {
    totalRequestsMade++;
    return {};
  }

  @override
  Future<dynamic> post(String path,
      {dynamic data,
      Map<String, dynamic>? queryParameters,
      Options? options}) async {
    totalRequestsMade++;
    return {};
  }

  @override
  Future<dynamic> delete(String path,
      {dynamic data,
      Map<String, dynamic>? queryParameters,
      Options? options}) async {
    totalRequestsMade++;
    return {};
  }
}

void main() {
  group('API Foundation Hardening Audit Tests (Step 2.1)', () {
    // -------------------------------------------------------------------------
    // A. UNDOCUMENTED /auth/login DOES NOT EXIST
    // -------------------------------------------------------------------------
    test('A. Undocumented /auth/login endpoint is completely removed', () {
      // The only authentication endpoints for the Farmer App in API_CONTRACT §2 are:
      expect(ApiEndpoints.authOtpRequest, '/auth/otp/request');
      expect(ApiEndpoints.authOtpVerify, '/auth/otp/verify');

      // Verify that no endpoint path matches /auth/login
      final allDeclaredEndpoints = [
        ApiEndpoints.authOtpRequest,
        ApiEndpoints.authOtpVerify,
        ApiEndpoints.assetsPresign,
        ApiEndpoints.voiceTranscribe,
        ApiEndpoints.voiceSynthesize,
        ApiEndpoints.farms,
        ApiEndpoints.farmDetail('f_1'),
        ApiEndpoints.farmSummary('f_1'),
        ApiEndpoints.diagnose('f_1'),
        ApiEndpoints.clarify('p_1'),
        ApiEndpoints.advisoryQuery,
        ApiEndpoints.labelCheck('p_1'),
        ApiEndpoints.alerts('f_1'),
        ApiEndpoints.alertRespond('al_1'),
        ApiEndpoints.timeline('f_1'),
        ApiEndpoints.problems('f_1'),
        ApiEndpoints.problemDetail('p_1'),
        ApiEndpoints.pendingFollowUps('f_1'),
        ApiEndpoints.followUpRespond('fu_1'),
        ApiEndpoints.escalate('p_1'),
        ApiEndpoints.referrals('f_1'),
        ApiEndpoints.health,
      ];

      for (final ep in allDeclaredEndpoints) {
        expect(ep, isNot(equals('/auth/login')));
      }
    });

    // -------------------------------------------------------------------------
    // B. LOCAL LOGOUT ONLY
    // -------------------------------------------------------------------------
    test('B. Local logout clears secure session state without HTTP requests',
        () async {
      final memoryStorage = InMemorySecureStorage();
      final tokenStorage = TokenStorage(storage: memoryStorage);
      final countingClient =
          RequestCountingApiClient(tokenStorage: tokenStorage);

      final authRepo = AuthRepositoryImpl(
        apiClient: countingClient,
        tokenStorage: tokenStorage,
      );

      // Setup active session
      await tokenStorage.saveTokens(
        accessToken: 'access_jwt_valid',
        refreshToken: 'refresh_jwt_valid',
      );
      await tokenStorage.saveUserData({'id': 'u_farmer_1', 'role': 'farmer'});
      await tokenStorage.saveActiveFarmId('f_100');

      expect(await authRepo.isAuthenticated(), isTrue);

      // Execute logout
      await authRepo.logout();

      // Verify ZERO network calls were made
      expect(countingClient.totalRequestsMade, 0,
          reason: 'Logout must be a purely local operation with zero HTTP calls');

      // Verify all secure tokens and context were deleted
      expect(await authRepo.isAuthenticated(), isFalse);
      expect(await tokenStorage.getAccessToken(), isNull);
      expect(await tokenStorage.getRefreshToken(), isNull);
      expect(await tokenStorage.getUserData(), isNull);
      expect(await tokenStorage.getActiveFarmId(), isNull);
    });

    // -------------------------------------------------------------------------
    // C. AUTH STARTUP STATE
    // -------------------------------------------------------------------------
    test('C1. Auth startup transitions to authenticated when token exists',
        () async {
      final memoryStorage = InMemorySecureStorage();
      final tokenStorage = TokenStorage(storage: memoryStorage);
      final client = RequestCountingApiClient(tokenStorage: tokenStorage);

      await tokenStorage.saveTokens(
        accessToken: 'valid_token_123',
        refreshToken: 'valid_refresh_456',
      );
      await tokenStorage
          .saveUserData({'id': 'u_1', 'phone': '+919876543210', 'role': 'farmer'});

      final authRepo = AuthRepositoryImpl(
        apiClient: client,
        tokenStorage: tokenStorage,
      );

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepo),
        ],
      );
      addTearDown(container.dispose);

      // Initial state is initializing
      expect(container.read(authStateProvider).isInitializing, isTrue);

      // Wait for checkAuthStatus() to finish
      await container.read(authStateProvider.notifier).checkAuthStatus();

      final state = container.read(authStateProvider);
      expect(state.isAuthenticated, isTrue);
      expect(state.isInitializing, isFalse);
      expect(state.user?.id, 'u_1');
    });

    test('C2. Auth startup transitions to unauthenticated when token is absent',
        () async {
      final memoryStorage = InMemorySecureStorage();
      final tokenStorage = TokenStorage(storage: memoryStorage);
      final client = RequestCountingApiClient(tokenStorage: tokenStorage);

      final authRepo = AuthRepositoryImpl(
        apiClient: client,
        tokenStorage: tokenStorage,
      );

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authStateProvider.notifier).checkAuthStatus();

      final state = container.read(authStateProvider);
      expect(state.isUnauthenticated, isTrue);
      expect(state.isAuthenticated, isFalse);
      expect(state.isInitializing, isFalse);
      expect(state.user, isNull);
    });

    // -------------------------------------------------------------------------
    // D, E, F. DIAGNOSIS POLYMORPHISM & NULLABILITY AUDIT
    // -------------------------------------------------------------------------
    test('D, E, F. Diagnosis polymorphic responses enforce nullability rules',
        () {
      // 1. Advise outcome: advisory exists, clarification & escalation MUST be null
      final adviseJson = {
        'gate': {
          'outcome': 'advise',
          'confidence': 0.85,
          'threshold_applied': 0.70,
          'reason_code': 'ABOVE_GATE',
          'alternatives': [
            {'label': 'blast', 'confidence': 0.85}
          ],
        },
        'problem_id': 'p_1',
        'problem_type': 'disease',
        'diagnosis': {'label': 'blast', 'severity': 'early'},
        'advisory': {
          'possible_issue': 'Paddy Blast',
          'what_to_check': 'Diamond spots',
          'what_to_avoid': 'No nitrogen',
          'ladder': [],
        },
      };

      final adviseRes = DiagnoseResponse.fromJson(adviseJson);
      expect(adviseRes.isAdvise, isTrue);
      expect(adviseRes.advisory, isNotNull);
      expect(adviseRes.clarification, isNull);
      expect(adviseRes.escalation, isNull);

      // 2. Clarify outcome: clarification exists, advisory & escalation MUST be null
      final clarifyJson = {
        'gate': {
          'outcome': 'clarify',
          'confidence': 0.55,
          'threshold_applied': 0.15,
          'reason_code': 'AMBIGUOUS',
          'alternatives': [
            {'label': 'blast', 'confidence': 0.55},
            {'label': 'brown_spot', 'confidence': 0.50}
          ],
        },
        'problem_id': 'p_1',
        'clarification': {
          'cue_id': 'cue_1',
          'question': 'Do you see fuzzy grey growth on leaf underside?',
          'candidates': [
            {'label': 'blast', 'signature': 'Diamond lesions'},
            {'label': 'brown_spot', 'signature': 'Round halo spots'}
          ],
          'answers': ['yes', 'no', 'unknown']
        },
      };

      final clarifyRes = DiagnoseResponse.fromJson(clarifyJson);
      expect(clarifyRes.isClarify, isTrue);
      expect(clarifyRes.clarification, isNotNull);
      expect(clarifyRes.advisory, isNull);
      expect(clarifyRes.escalation, isNull);

      // 3. Escalate outcome: escalation exists, advisory & clarification MUST be null
      final escalateJson = {
        'gate': {
          'outcome': 'escalate',
          'confidence': 0.30,
          'threshold_applied': 0.45,
          'reason_code': 'BELOW_FLOOR',
          'alternatives': [
            {'label': 'blast', 'confidence': 0.30}
          ],
        },
        'problem_id': 'p_1',
        'escalation': {
          'case_id': 'c_1',
          'assigned_to': 'KVK Nashik',
          'queue_position': 1,
          'eta_minutes': 30
        },
      };

      final escalateRes = DiagnoseResponse.fromJson(escalateJson);
      expect(escalateRes.isEscalate, isTrue);
      expect(escalateRes.escalation, isNotNull);
      expect(escalateRes.advisory, isNull);
      expect(escalateRes.clarification, isNull);
    });

    // -------------------------------------------------------------------------
    // I. EXACT 23 DOCUMENTED ENDPOINTS IN API_CONTRACT.md
    // -------------------------------------------------------------------------
    test('I. All 23 documented endpoints match API_CONTRACT.md paths exactly', () {
      expect(ApiEndpoints.authOtpRequest, '/auth/otp/request');
      expect(ApiEndpoints.authOtpVerify, '/auth/otp/verify');
      expect(ApiEndpoints.assetsPresign, '/assets/presign');
      expect(ApiEndpoints.voiceTranscribe, '/voice/transcribe');
      expect(ApiEndpoints.voiceSynthesize, '/voice/synthesize');
      expect(ApiEndpoints.farms, '/farms');
      expect(ApiEndpoints.farmDetail('f_1'), '/farms/f_1');
      expect(ApiEndpoints.farmSummary('f_1'), '/farms/f_1/summary');
      expect(ApiEndpoints.diagnose('f_1'), '/farms/f_1/diagnose');
      expect(ApiEndpoints.clarify('p_1'), '/problems/p_1/clarify');
      expect(ApiEndpoints.advisoryQuery, '/advisory/query');
      expect(ApiEndpoints.labelCheck('p_1'), '/problems/p_1/label-check');
      expect(ApiEndpoints.alerts('f_1'), '/farms/f_1/alerts');
      expect(ApiEndpoints.alertRespond('al_1'), '/alerts/al_1/respond');
      expect(ApiEndpoints.timeline('f_1'), '/farms/f_1/timeline');
      expect(ApiEndpoints.problems('f_1'), '/farms/f_1/problems');
      expect(ApiEndpoints.problemDetail('p_1'), '/problems/p_1');
      expect(ApiEndpoints.pendingFollowUps('f_1'), '/farms/f_1/followups/pending');
      expect(ApiEndpoints.followUpRespond('fu_1'), '/followups/fu_1/respond');
      expect(ApiEndpoints.escalate('p_1'), '/problems/p_1/escalate');
      expect(ApiEndpoints.referrals('f_1'), '/farms/f_1/referrals');
      expect(ApiEndpoints.health, '/health');
    });

    // -------------------------------------------------------------------------
    // J. SAFETY INVARIANTS: NO ENDORSEMENT IN VERDICTS
    // -------------------------------------------------------------------------
    test('J. Zero endorsement vocabulary in all verdict strings', () {
      const forbiddenEndorsements = [
        'safe',
        'approved',
        'you can use',
        'recommended',
        'endorse',
      ];

      for (final entry in AppConstants.verdictMessages.entries) {
        final lower = entry.value.toLowerCase();
        for (final word in forbiddenEndorsements) {
          expect(lower.contains(word), isFalse,
              reason: 'Verdict code "${entry.key}" must never endorse or use "$word"');
        }
      }
    });
  });
}
