import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/localization/app_strings.dart';
import '../../../widgets/language_selector_button.dart';
import '../../onboarding/presentation/phone_auth_screen.dart';

/// Launch Landing & Welcome Screen for Bhoomi.
/// Establishes the agricultural brand identity and the "Talk, Show, Listen"
/// core product pillars before entering authentication.
class LandingScreen extends ConsumerStatefulWidget {
  const LandingScreen({super.key});

  @override
  ConsumerState<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends ConsumerState<LandingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutQuad,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onStartPressed() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PhoneAuthScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);

    return Scaffold(
      backgroundColor: AppColors.ricePaper,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.l20,
                          vertical: AppSpacing.m12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 1. TOP BRANDING & LANGUAGE HEADER
                            _buildTopHeader(strings),
                            const SizedBox(height: AppSpacing.m12),

                            // 2. HERO AGRICULTURAL ILLUSTRATION
                            Expanded(
                              flex: 6,
                              child: _buildHeroIllustration(constraints),
                            ),
                            const SizedBox(height: AppSpacing.m16),

                            // 3. PRODUCT PILLARS (TALK, SHOW, LISTEN)
                            _buildProductPillars(strings),
                            const SizedBox(height: AppSpacing.m12),

                            // 4. VALUE PROPOSITION MESSAGE
                            Text(
                              strings.landingHeroTagline,
                              textAlign: TextAlign.center,
                              style: AppTypography.subheading.copyWith(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w700,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.l20),

                            // 5. PRIMARY "START" CTA
                            _buildStartCtaButton(strings),
                            const SizedBox(height: AppSpacing.m12),

                            // 6. BOTTOM SUBTLE BRANDING & LANGUAGE ACCESS
                            _buildFooter(strings),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // TOP BRANDING & LANGUAGE HEADER
  // ===========================================================================
  Widget _buildTopHeader(AppStrings strings) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Brand Mark + Title + Tagline
        Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Circular Logo Mark
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.forest, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.forest.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'assets/images/bhoomi_logo_mark.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(
                        Icons.eco_rounded,
                        color: AppColors.forest,
                        size: 26,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.s10),

              // Wordmark + Companion Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      strings.landingTitle,
                      style: AppTypography.sectionTitle.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        letterSpacing: -0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      strings.landingSubtitle,
                      style: AppTypography.captionSmall.copyWith(
                        color: AppColors.forest,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.s8),

        // Global Language Switcher Pill
        const LanguageSelectorButton(),
      ],
    );
  }

  // ===========================================================================
  // HERO AGRICULTURAL ILLUSTRATION
  // ===========================================================================
  Widget _buildHeroIllustration(BoxConstraints constraints) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 160,
        maxHeight: 320,
      ),
      decoration: BoxDecoration(
        color: AppColors.warmSurface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.soilCharcoal.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Farmer Artwork
          Image.asset(
            'assets/images/bhoomi_farmer_hero.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primaryLight,
                      AppColors.warmSurface,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.agriculture_rounded,
                      size: 72,
                      color: AppColors.forest.withValues(alpha: 0.8),
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    Text(
                      'Bhoomi Farmer Companion',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.forest,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Subtle Bottom Gradient to seamlessly ground the illustration
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 48,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.25),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // PRODUCT PILLARS (TALK, SHOW, LISTEN)
  // ===========================================================================
  Widget _buildProductPillars(AppStrings strings) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildPillarChip(
            icon: Icons.mic_rounded,
            label: strings.landingPillarTalk,
            color: AppColors.forest,
            bgColor: AppColors.primaryLight,
          ),
          const SizedBox(width: AppSpacing.s8),
          _buildPillarDivider(),
          const SizedBox(width: AppSpacing.s8),
          _buildPillarChip(
            icon: Icons.photo_camera_rounded,
            label: strings.landingPillarShow,
            color: AppColors.primaryDark,
            bgColor: AppColors.primaryLight,
          ),
          const SizedBox(width: AppSpacing.s8),
          _buildPillarDivider(),
          const SizedBox(width: AppSpacing.s8),
          _buildPillarChip(
            icon: Icons.volume_up_rounded,
            label: strings.landingPillarListen,
            color: AppColors.forest,
            bgColor: AppColors.primaryLight,
          ),
        ],
      ),
    );
  }

  Widget _buildPillarChip({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m12,
        vertical: AppSpacing.s6,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: AppSpacing.s6),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillarDivider() {
    return const Icon(
      Icons.arrow_forward_ios_rounded,
      size: 12,
      color: AppColors.border,
    );
  }

  // ===========================================================================
  // PRIMARY "START" CTA BUTTON
  // ===========================================================================
  Widget _buildStartCtaButton(AppStrings strings) {
    return Semantics(
      button: true,
      label: strings.landingSemanticsStart,
      child: Material(
        color: AppColors.forest,
        borderRadius: BorderRadius.circular(16),
        elevation: 4,
        shadowColor: AppColors.forest.withValues(alpha: 0.4),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _onStartPressed,
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '🌱',
                  style: TextStyle(fontSize: 22),
                ),
                const SizedBox(width: AppSpacing.s10),
                Text(
                  strings.landingGetStarted,
                  style: AppTypography.button.copyWith(
                    color: AppColors.pureWhite,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: AppSpacing.s10),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.pureWhite,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // FOOTER WITH SUBTLE BRANDING
  // ===========================================================================
  Widget _buildFooter(AppStrings strings) {
    return Center(
      child: Text(
        'SIH26131 • ICAR Grounded • Marathi & Hindi',
        style: AppTypography.captionSmall.copyWith(
          color: AppColors.fieldSlate,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
