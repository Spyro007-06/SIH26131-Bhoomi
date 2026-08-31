import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../providers/auth_providers.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/app_text_field.dart';

/// OTP Verification Screen for Bhoomi Farmer App.
class OtpVerifyScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  final String requestId;
  final int expiresInSeconds;

  const OtpVerifyScreen({
    super.key,
    required this.phoneNumber,
    required this.requestId,
    this.expiresInSeconds = 300,
  });

  @override
  ConsumerState<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends ConsumerState<OtpVerifyScreen> {
  final TextEditingController _otpController = TextEditingController();
  late String _currentRequestId;
  late int _remainingSeconds;
  Timer? _countdownTimer;
  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentRequestId = widget.requestId;
    _remainingSeconds = widget.expiresInSeconds > 0 ? widget.expiresInSeconds : 300;
    _startCountdown();
    _otpController.addListener(_onOtpChanged);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _otpController.removeListener(_onOtpChanged);
    _otpController.dispose();
    super.dispose();
  }

  void _onOtpChanged() {
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    } else {
      setState(() {});
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  bool get _isOtpValid => _otpController.text.trim().length == 6;

  String _formatPhoneNumber(String phone) {
    if (phone.length >= 13) {
      return '${phone.substring(0, 3)} ${phone.substring(3, 8)} ${phone.substring(8)}';
    }
    return phone;
  }

  Future<void> _handleVerifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      final strings = ref.read(stringsProvider);
      setState(() => _errorMessage = strings.invalidOtpLength);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authStateProvider.notifier).verifyOtp(
            requestId: _currentRequestId,
            otp: otp,
          );

      _countdownTimer?.cancel();
      if (!mounted) return;
      setState(() => _isLoading = false);

      // Pop all onboarding routes; Root routing in main.dart / app shell will render MainAppShell
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      final strings = ref.read(stringsProvider);
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().contains('400') || e.toString().contains('INVALID_OTP')
            ? strings.invalidOtpError
            : strings.genericError;
      });
    }
  }

  Future<void> _handleResendOtp() async {
    if (_remainingSeconds > 0 || _isResending) return;

    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    try {
      final response = await ref
          .read(authStateProvider.notifier)
          .requestOtp(widget.phoneNumber);

      if (!mounted) return;
      setState(() {
        _currentRequestId = response.requestId;
        _remainingSeconds = response.expiresIn > 0 ? response.expiresIn : 300;
        _isResending = false;
        _otpController.clear();
      });
      _startCountdown();
    } catch (e) {
      if (!mounted) return;
      final strings = ref.read(stringsProvider);
      setState(() {
        _isResending = false;
        _errorMessage = strings.genericError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);

    return Scaffold(
      backgroundColor: AppColors.ricePaper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.forest),
          tooltip: strings.changeNumber,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.l20,
                vertical: AppSpacing.m16,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - AppSpacing.xl32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.verifyNumberTitle,
                          style: AppTypography.title.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s8),

                        // Subtitle with Phone & Change CTA
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                strings.otpSentTo(_formatPhoneNumber(widget.phoneNumber)),
                                style: AppTypography.body.copyWith(
                                  color: AppColors.fieldSlate,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xl28),

                        // OTP Input Card
                        AppCard(
                          padding: const EdgeInsets.all(AppSpacing.l20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                strings.enterOtpHint,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.soilCharcoal,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.m12),
                              AppTextField(
                                controller: _otpController,
                                hintText: '• • • • • •',
                                keyboardType: TextInputType.number,
                                errorText: _errorMessage,
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                  color: AppColors.fieldSlate,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.m16),

                              // Resend Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      strings.didntReceiveOtp,
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.fieldSlate,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.s8),
                                  if (_remainingSeconds > 0)
                                    Text(
                                      strings.resendIn(_remainingSeconds),
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.forest,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    )
                                  else
                                    TextButton(
                                      onPressed: _isResending ? null : _handleResendOtp,
                                      child: Text(
                                        strings.resendOtp,
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.forest,
                                          fontWeight: FontWeight.w800,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Bottom CTA Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: AppSpacing.xl32),
                        AppButton.primary(
                          label: strings.verifyOtp,
                          size: AppButtonSize.large,
                          isFullWidth: true,
                          isLoading: _isLoading,
                          onPressed: _isOtpValid && !_isLoading
                              ? _handleVerifyOtp
                              : null,
                          leadingIcon: const Icon(
                            Icons.check_circle_outline_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s10),
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              strings.changeNumber,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.fieldSlate,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
