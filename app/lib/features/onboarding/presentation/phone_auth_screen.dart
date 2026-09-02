import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/demo_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../providers/auth_providers.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/language_selector_button.dart';
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

  void _showDemoConfirmationModal(BuildContext context) {
    final strings = ref.read(stringsProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.ricePaper,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.l24,
              vertical: AppSpacing.l20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.s8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.forest.withValues(alpha: 0.3)),
                      ),
                      child: const Icon(
                        Icons.agriculture_rounded,
                        color: AppColors.forest,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.m12),
                    Expanded(
                      child: Text(
                        strings.demoModalTitle,
                        style: AppTypography.sectionTitle.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.m16),
                Text(
                  strings.demoModalDesc,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.soilCharcoal,
                  ),
                ),
                const SizedBox(height: AppSpacing.m16),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.m16),
                  decoration: BoxDecoration(
                    color: AppColors.warmSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDemoDetailRow(
                        icon: Icons.person_rounded,
                        text: strings.demoFarmerNameLabel,
                      ),
                      const SizedBox(height: AppSpacing.s8),
                      _buildDemoDetailRow(
                        icon: Icons.grass_rounded,
                        text: strings.demoFarmNameLabel,
                      ),
                      const SizedBox(height: AppSpacing.s8),
                      _buildDemoDetailRow(
                        icon: Icons.location_on_rounded,
                        text: strings.demoLocationLabel,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.l24),
                AppButton.primary(
                  label: strings.enterDemoButton,
                  size: AppButtonSize.large,
                  isFullWidth: true,
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _handleDemoLogin();
                  },
                  leadingIcon: const Icon(Icons.login_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(height: AppSpacing.s10),
                AppButton.ghost(
                  label: strings.cancel,
                  size: AppButtonSize.normal,
                  isFullWidth: true,
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDemoDetailRow({required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.forest),
        const SizedBox(width: AppSpacing.s8),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleDemoLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authStateProvider.notifier).loginAsDemo();
      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
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
                vertical: AppSpacing.m16,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - (AppSpacing.m16 * 2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.m16),

                        // App Logo Emblem & Global Language Selector
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
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
                            const Flexible(
                              child: LanguageSelectorButton(),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.l20),

                        // Welcome Headlines
                        Text(
                          strings.welcomeTitle,
                          style: AppTypography.screenTitle.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s8),
                        Text(
                          strings.phoneSubtitle,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.soilCharcoal.withValues(alpha: 0.8),
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
                        if (DemoConfig.isDemoMode) ...[
                          const SizedBox(height: AppSpacing.s8),
                          Center(
                            child: TextButton.icon(
                              onPressed: _isLoading
                                  ? null
                                  : () => _showDemoConfirmationModal(context),
                              icon: const Text('🌾', style: TextStyle(fontSize: 16)),
                              label: Text(
                                strings.tryDemoAccount,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.forest,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
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
