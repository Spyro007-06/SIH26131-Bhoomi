import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_models.dart';
import 'repository_providers.dart';
import 'farm_providers.dart';
import 'feature_providers.dart';

enum AuthStatus {
  initializing,
  authenticated,
  unauthenticated,
}

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;
  final bool isLoading;

  const AuthState({
    this.status = AuthStatus.initializing,
    this.user,
    this.errorMessage,
    this.isLoading = false,
  });

  bool get isInitializing => status == AuthStatus.initializing;
  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isUnauthenticated => status == AuthStatus.unauthenticated;

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
    bool? isLoading,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;

  AuthNotifier(this._ref) : super(const AuthState(status: AuthStatus.initializing, isLoading: true)) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    state = state.copyWith(status: AuthStatus.initializing, isLoading: true);
    try {
      final authRepo = _ref.read(authRepositoryProvider);
      final isAuthed = await authRepo.isAuthenticated();
      if (isAuthed) {
        final user = await authRepo.getCurrentUser();
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          isLoading: false,
          errorMessage: null,
        );
      } else {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          user: null,
          isLoading: false,
          errorMessage: null,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        user: null,
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<OtpRequestResponse> requestOtp(String phone) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final authRepo = _ref.read(authRepositoryProvider);
      final res = await authRepo.requestOtp(phone: phone);
      state = state.copyWith(isLoading: false);
      return res;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  Future<OtpVerifyResponse> verifyOtp({
    required String requestId,
    required String otp,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final authRepo = _ref.read(authRepositoryProvider);
      final res = await authRepo.verifyOtp(requestId: requestId, otp: otp);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: res.user,
        isLoading: false,
      );
      return res;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  Future<OtpVerifyResponse> loginAsDemo({String demoCode = 'SIH2026'}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final authRepo = _ref.read(authRepositoryProvider);
      final res = await authRepo.loginAsDemo(demoCode: demoCode);

      // Auto-set the demo farm context for the demo session
      await _ref.read(activeFarmIdProvider.notifier).setActiveFarmId('f_demo_01');

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: res.user,
        isLoading: false,
      );
      return res;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> logout() async {
    final authRepo = _ref.read(authRepositoryProvider);
    await authRepo.logout();

    // Reset and invalidate all farmer-specific state on logout
    _ref.read(activeFarmIdProvider.notifier).clearActiveFarm();
    _ref.invalidate(activeFarmSummaryProvider);
    _ref.invalidate(activeAlertsProvider);
    _ref.invalidate(pendingFollowUpsProvider);
    _ref.invalidate(farmTimelineProvider);
    _ref.invalidate(farmReferralsProvider);

    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authStateProvider).user;
});
