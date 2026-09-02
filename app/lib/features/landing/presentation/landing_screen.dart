import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/localization/app_strings.dart';
import '../../../widgets/language_selector_button.dart';
import '../../onboarding/presentation/phone_auth_screen.dart';

/// Launch Landing & Welcome Screen for Bhoomi.
/// Faithfully reproduces the reference design with full-bleed agricultural artwork,
/// top branding, 3 core pillars (Talk, Show, Listen), and primary Start CTA.
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
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.04),
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
      backgroundColor: const Color(0xFF0C2B14),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. FULL-BLEED BACKGROUND ARTWORK
          _buildBackgroundArtwork(),

          // 2. MAIN RESPONSIVE FOREGROUND CONTENT
          SafeArea(
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // TOP BRANDING SECTION (OVER SKY)
                              _buildTopBranding(strings),

                              // SPACER / MIDDLE FARMER VISUAL AREA
                              const Spacer(flex: 2),

                              // BOTTOM DARK GREEN ACTION CARD
                              _buildBottomCard(strings),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 1. FULL-BLEED BACKGROUND ARTWORK
  // ===========================================================================
  Widget _buildBackgroundArtwork() {
    return Positioned.fill(
      child: Image.asset(
        'assets/images/bhoomi_farmer_hero.png',
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFBE8C8),
                  Color(0xFFE2EED8),
                  Color(0xFF0F3819),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // 2. TOP BRANDING SECTION (EMBLEM, TITLE, TAGLINE, SUBTITLE)
  // ===========================================================================
  Widget _buildTopBranding(AppStrings strings) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.m16,
        left: AppSpacing.l20,
        right: AppSpacing.l20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Circular Logo Emblem
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
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
                    color: Color(0xFF1B5E20),
                    size: 34,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),

          // "Bhoomi" Wordmark
          Text(
            strings.landingTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF114216),
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              height: 1.1,
              fontFamily: 'serif',
            ),
          ),
          const SizedBox(height: 4),

          // Tagline with decorative lines: "— तुमचा शेतकरी साथी —"
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24,
                  height: 1.5,
                  color: const Color(0xFF2E7D32),
                ),
                const SizedBox(width: AppSpacing.s8),
                Text(
                  strings.landingTagline,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF1B5E20),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: AppSpacing.s8),
                Container(
                  width: 24,
                  height: 1.5,
                  color: const Color(0xFF2E7D32),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),

          // Subtitle: "AI-आधारित शेतकरी साथी"
          Text(
            strings.landingSubtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF235528),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. BOTTOM DARK GREEN ACTION CARD
  // ===========================================================================
  Widget _buildBottomCard(AppStrings strings) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.s10),
      padding: const EdgeInsets.only(
        top: AppSpacing.l20,
        left: AppSpacing.m16,
        right: AppSpacing.m16,
        bottom: AppSpacing.m16,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0B2E15).withValues(alpha: 0.95),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        border: Border.all(
          color: const Color(0xFF2E7D32).withValues(alpha: 0.5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Value Proposition Heading
          Text(
            strings.landingHeroMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFF7F4EB),
              fontSize: 17,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          const SizedBox(height: AppSpacing.l16),

          // 2. Three Product Pillar Columns (Talk, Show, Listen)
          _buildPillarColumns(strings),
          const SizedBox(height: AppSpacing.l20),

          // 3. Primary Start CTA Button
          _buildStartButton(strings),
          const SizedBox(height: AppSpacing.m12),

          // 4. Centered Language Selector Pill
          _buildLanguageSelectorRow(),
          const SizedBox(height: AppSpacing.s6),

          // 5. Decorative Layered Waves at Base
          _buildBottomDecorativeWaves(),
        ],
      ),
    );
  }

  // ===========================================================================
  // THREE PILLAR COLUMNS (TALK, SHOW, LISTEN)
  // ===========================================================================
  Widget _buildPillarColumns(AppStrings strings) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s6,
        vertical: AppSpacing.s10,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. TALK / BOLO
          Expanded(
            child: _buildPillarItem(
              icon: Icons.mic_rounded,
              title: strings.landingTalkTitle,
              subtitle: strings.landingTalkSubtitle,
              hasGlow: true,
            ),
          ),
          _buildVerticalDivider(),

          // 2. SHOW / DAKHVA
          Expanded(
            child: _buildPillarItem(
              icon: Icons.photo_camera_rounded,
              title: strings.landingShowTitle,
              subtitle: strings.landingShowSubtitle,
              hasGlow: false,
            ),
          ),
          _buildVerticalDivider(),

          // 3. LISTEN / AIKA
          Expanded(
            child: _buildPillarItem(
              icon: Icons.volume_up_rounded,
              title: strings.landingListenTitle,
              subtitle: strings.landingListenSubtitle,
              hasGlow: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillarItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool hasGlow,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Circular Icon Tile with subtle glow
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFF9F6EE),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: hasGlow
                    ? const Color(0xFFFFD54F).withValues(alpha: 0.5)
                    : Colors.black.withValues(alpha: 0.15),
                blurRadius: hasGlow ? 12 : 6,
                spreadRadius: hasGlow ? 2 : 0,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: hasGlow
                  ? const Color(0xFFFFC107)
                  : const Color(0xFFC8E6C9),
              width: hasGlow ? 2 : 1,
            ),
          ),
          child: Center(
            child: Icon(
              icon,
              color: const Color(0xFF1B5E20),
              size: 26,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s8),

        // Pillar Title (बोला / दाखवा / ऐका)
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 16,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 3),

        // Pillar Subtitle (शंका विचारा / पिकाचा फोटो घ्या / योग्य सल्ला ऐका)
        Text(
          subtitle,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFFA5D6A7),
            fontSize: 11,
            fontWeight: FontWeight.w500,
            height: 1.15,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: Colors.white.withValues(alpha: 0.12),
    );
  }

  // ===========================================================================
  // PRIMARY START CTA BUTTON
  // ===========================================================================
  Widget _buildStartButton(AppStrings strings) {
    return Semantics(
      button: true,
      label: strings.landingSemanticsStart,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: _onStartPressed,
          child: Ink(
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF66BB6A),
                  Color(0xFF43A047),
                  Color(0xFF2E7D32),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: const Color(0xFFA5D6A7).withValues(alpha: 0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF43A047).withValues(alpha: 0.45),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l20),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '🌱',
                      style: TextStyle(fontSize: 22),
                    ),
                    const SizedBox(width: AppSpacing.s10),
                    Text(
                      strings.landingStartButton,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s10),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // CENTERED LANGUAGE SELECTOR ROW
  // ===========================================================================
  Widget _buildLanguageSelectorRow() {
    return const Center(
      child: LanguageSelectorButton(
        isDarkBackground: true,
      ),
    );
  }

  // ===========================================================================
  // BOTTOM DECORATIVE CURVED WAVES
  // ===========================================================================
  Widget _buildBottomDecorativeWaves() {
    return SizedBox(
      height: 14,
      child: CustomPaint(
        painter: _BottomWavePainter(),
      ),
    );
  }
}

/// Custom painter rendering the layered wave curves at the bottom of the card.
class _BottomWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = const Color(0xFF1B5E20).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path1 = Path()
      ..moveTo(0, size.height * 0.8)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.2,
        size.width,
        size.height * 0.6,
      );

    canvas.drawPath(path1, paint1);

    final paint2 = Paint()
      ..color = const Color(0xFF43A047).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path2 = Path()
      ..moveTo(0, size.height * 0.4)
      ..quadraticBezierTo(
        size.width * 0.6,
        size.height * 0.9,
        size.width,
        size.height * 0.3,
      );

    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
