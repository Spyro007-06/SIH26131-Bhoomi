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
import 'otp_verify_screen.dart';

/// Phone authentication entrypoint screen for Bhoomi Farmer App.
class PhoneAuthScreen extends ConsumerStatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  ConsumerState<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends ConsumerState<PhoneAuthScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_onPhoneChanged);
  }

  @override
  void dispose() {
    _phoneController.removeListener(_onPhoneChanged);
    _phoneController.dispose();
    super.dispose();
  }

  void _onPhoneChanged() {
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    } else {
      setState(() {});
    }
  }

  bool get _isPhoneValid => _phoneController.text.trim().length == 10;

  Future<void> _handleSendOtp() async {
    final rawPhone = _phoneController.text.trim();
    if (rawPhone.length != 10) {
      final strings = ref.read(stringsProvider);
      setState(() => _errorMessage = strings.invalidPhoneError);
      return;
    }

    final fullPhone = '+91$rawPhone';
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ref.read(authStateProvider.notifier).requestOtp(fullPhone);

      if (!mounted) return;
      setState(() => _isLoading = false);

      // Navigate to OTP verification screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => OtpVerifyScreen(
            phoneNumber: fullPhone,
            requestId: response.requestId,
            expiresInSeconds: response.expiresIn,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final strings = ref.read(stringsProvider);
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().contains('network') || e.toString().contains('SocketException')
            ? strings.networkError
            : strings.genericError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);

    return Scaffold(
      backgroundColor: AppColors.ricePaper,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.l20,
                vertical: AppSpacing.xl28,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - (AppSpacing.xl28 * 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Section: Brand & Welcome
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.m16),
                        // App Logo Emblem
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.forest, width: 2),
                          ),
                          child: const Icon(
                            Icons.eco_rounded,
                            size: 36,
                            color: AppColors.forest,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.l20),

                        // Welcome Heading
                        Text(
                          strings.welcomeTitle,
                          style: AppTypography.title.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s8),

                        // Subtitle
                        Text(
                          strings.phoneSubtitle,
                          style: AppTypography.body.copyWith(
                            color: AppColors.fieldSlate,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl32),

                        // Phone Input Card
                        AppCard(
                          padding: const EdgeInsets.all(AppSpacing.l20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                strings.phoneLabel,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.soilCharcoal,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.s8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Non-editable India country code box
                                  Container(
                                    height: 54,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.m12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight.withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.border,
                                        width: 1.2,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '🇮🇳 +91',
                                          style: AppTypography.bodyMedium.copyWith(
                                            color: AppColors.primaryDark,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.s8),

                                  // Phone input field
                                  Expanded(
                                    child: AppTextField(
                                      controller: _phoneController,
                                      hintText: strings.phoneHint,
                                      keyboardType: TextInputType.phone,
                                      errorText: _errorMessage,
                                      prefixIcon: const Icon(
                                        Icons.phone_rounded,
                                        color: AppColors.fieldSlate,
                                        size: 20,
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

                    // Bottom Action Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: AppSpacing.xl32),
                        AppButton.primary(
                          label: strings.sendOtp,
                          size: AppButtonSize.large,
                          isFullWidth: true,
                          isLoading: _isLoading,
                          onPressed: _isPhoneValid && !_isLoading
                              ? _handleSendOtp
                              : null,
                          trailingIcon: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.m16),
                        Center(
                          child: Text(
                            strings.appTagline,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.fieldSlate,
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
