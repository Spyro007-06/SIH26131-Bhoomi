import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_radius.dart';

/// IPM Action ladder item data
class LadderRung {
  final String tier; // 'cultural' | 'biological' | 'chemical'
  final String action;
  final String? dosage;
  final int? phiDays;
  final int? reentryHours;

  const LadderRung({
    required this.tier,
    required this.action,
    this.dosage,
    this.phiDays,
    this.reentryHours,
  });
}

/// Citation source item data
class AdvisoryCitation {
  final String docId;
  final String title;
  final String reviewedOn;

  const AdvisoryCitation({
    required this.docId,
    required this.title,
    required this.reviewedOn,
  });
}

/// Grounded Advisory Component with IPM Ladder (F7, PRD §5, API_CONTRACT §8).
///
/// Order & Invariants:
/// 1. Possible issue & confidence
/// 2. **What to avoid** — visually loudest warning callout, first thing seen
/// 3. What to check
/// 4. Action ladder: Cultural → Biological → Chemical (Chemical collapsed by default)
/// 5. Expert trigger
/// 6. Citations visible but secondary
/// 7. Spoken summary audio playback
class AdvisoryIpmCard extends StatefulWidget {
  final String possibleIssue;
  final String whatToAvoid;
  final String whatToCheck;
  final List<LadderRung> ladder;
  final String? expertTrigger;
  final List<AdvisoryCitation> citations;
  final String? spokenSummary;
  final VoidCallback? onPlayAudio;

  const AdvisoryIpmCard({
    super.key,
    this.possibleIssue = 'Early Paddy Blast (भातावरील करपा - सुरुवातीची अवस्था)',
    this.whatToAvoid = 'Do not top-dress nitrogen now. It accelerates fungal spread. (युरिया/नायट्रोजन खत देऊ नका, यामुळे रोग झपाट्याने वाढतो.)',
    this.whatToCheck = 'Diamond-shaped lesions with grey centres on upper leaves. (वरच्या पानांवर राखाडी केंद्र असलेले टोकदार ठिपके तपासा.)',
    this.ladder = const [
      LadderRung(
        tier: 'cultural',
        action: 'Drain the field and let the soil surface dry for 48 hours to reduce humidity. (शेतातील पाणी काढून ४८ तास वाळू द्या.)',
      ),
      LadderRung(
        tier: 'biological',
        action: 'Apply Pseudomonas fluorescens (10g/litre) as foliar spray in evening hours. (सूडोमोनास फ्लुरोसन्स फवारणी करा.)',
      ),
      LadderRung(
        tier: 'chemical',
        action: 'Tricyclazole 75% WP (ट्रायसायक्लॅझोल ७५% डब्ल्यूपी)',
        dosage: '0.6 g per litre of water',
        phiDays: 30,
        reentryHours: 24,
      ),
    ],
    this.expertTrigger = 'If lesions cover >25% of leaf area within 3 days, request expert review.',
    this.citations = const [
      AdvisoryCitation(
        docId: 'kb_211',
        title: 'ICAR Package of Practices: Rice — Blast Disease Management',
        reviewedOn: '2025-11-02',
      ),
    ],
    this.spokenSummary = 'सध्या शेतातील पाणी काढा आणि नायट्रोजन खत देणे टाळा...',
    this.onPlayAudio,
  });

  @override
  State<AdvisoryIpmCard> createState() => _AdvisoryIpmCardState();
}

class _AdvisoryIpmCardState extends State<AdvisoryIpmCard> {
  bool _isChemicalExpanded = false;
  bool _isPlayingAudio = false;

  @override
  Widget build(BuildContext context) {
    // Separate ladder tiers
    final culturalRungs = widget.ladder.where((r) => r.tier == 'cultural').toList();
    final biologicalRungs = widget.ladder.where((r) => r.tier == 'biological').toList();
    final chemicalRungs = widget.ladder.where((r) => r.tier == 'chemical').toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.warmSurface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border, width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Issue & Audio Playback
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.l16,
              vertical: AppSpacing.m12,
            ),
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppRadius.cardValue),
                topRight: Radius.circular(AppRadius.cardValue),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.eco_rounded, color: AppColors.forest, size: 24),
                const SizedBox(width: AppSpacing.s8),
                Expanded(
                  child: Text(
                    'Grounded Advisory (सल्ला व मार्गदर्शन)',
                    style: AppTypography.subhead.copyWith(
                      color: AppColors.primaryDark,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (widget.spokenSummary != null)
                  IconButton(
                    icon: Icon(
                      _isPlayingAudio
                          ? Icons.pause_circle_filled_rounded
                          : Icons.volume_up_rounded,
                      color: AppColors.forest,
                      size: 26,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPlayingAudio = !_isPlayingAudio;
                      });
                      widget.onPlayAudio?.call();
                    },
                    tooltip: 'Listen to spoken advisory',
                  ),
              ],
            ),
          ),

          Padding(
            padding: AppSpacing.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Issue
                Text(
                  widget.possibleIssue,
                  style: AppTypography.sectionTitle.copyWith(
                    color: AppColors.soilCharcoal,
                  ),
                ),
                const SizedBox(height: AppSpacing.l16),

                // 2. WHAT TO AVOID (VISUALLY LOUDEST CALLOUT)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.l16),
                  decoration: BoxDecoration(
                    color: AppColors.warningBg,
                    borderRadius: AppRadius.card,
                    border: Border.all(
                      color: AppColors.warning,
                      width: 2.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.xs4),
                            decoration: const BoxDecoration(
                              color: AppColors.warning,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.do_not_disturb_on_rounded,
                              color: AppColors.pureWhite,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s8),
                          Expanded(
                            child: Text(
                              'WHAT TO AVOID FIRST (हे अजिबात करू नका):',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s8),
                      Text(
                        widget.whatToAvoid,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.soilCharcoal,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.l16),

                // 3. What to check
                Container(
                  padding: const EdgeInsets.all(AppSpacing.m12),
                  decoration: BoxDecoration(
                    color: AppColors.ricePaper,
                    borderRadius: AppRadius.button,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.fact_check_outlined,
                        color: AppColors.info,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.s8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'WHAT TO CHECK IN THE FIELD (काय तपासावे):',
                              style: AppTypography.captionSmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.info,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.whatToCheck,
                              style: AppTypography.body.copyWith(
                                fontSize: 14,
                                color: AppColors.soilCharcoal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl24),

                // 4. IPM ACTION LADDER (Cultural -> Biological -> Chemical)
                Text(
                  'IPM ACTION LADDER (एकात्मिक कीड व्यवस्थापन पायऱ्या):',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.forest,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: AppSpacing.m12),

                // Step 1: Cultural Management
                _buildLadderSection(
                  stepNumber: '1',
                  stepTitle: 'Cultural Action (मशागतीय / जैविक उपाय)',
                  stepSubtitle: 'First-line non-chemical practices',
                  accentColor: AppColors.forest,
                  rungs: culturalRungs,
                ),
                const SizedBox(height: AppSpacing.m12),

                // Step 2: Biological Management
                _buildLadderSection(
                  stepNumber: '2',
                  stepTitle: 'Biological Action (जैविक नियंत्रण)',
                  stepSubtitle: 'Bio-agents & natural predators',
                  accentColor: AppColors.paddyGreen,
                  rungs: biologicalRungs,
                ),
                const SizedBox(height: AppSpacing.m12),

                // Step 3: Chemical Management (Collapsed by Default)
                _buildChemicalSection(chemicalRungs),

                // 5. Expert Trigger
                if (widget.expertTrigger != null) ...[
                  const SizedBox(height: AppSpacing.l16),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.m12),
                    decoration: BoxDecoration(
                      color: AppColors.dangerBg.withValues(alpha: 0.4),
                      borderRadius: AppRadius.button,
                      border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.support_agent_rounded, color: AppColors.danger, size: 20),
                        const SizedBox(width: AppSpacing.s8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'EXPERT ESCALATION TRIGGER (तज्ञ मदतीची वेळ):',
                                style: AppTypography.captionSmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.danger,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.expertTrigger!,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.soilCharcoal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // 6. Citations (Secondary)
                if (widget.citations.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.l16),
                  const Divider(height: 1, color: AppColors.subtleDivider),
                  const SizedBox(height: AppSpacing.m12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.menu_book_rounded, color: AppColors.fieldSlate, size: 16),
                      const SizedBox(width: AppSpacing.s8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: widget.citations
                              .map(
                                (c) => Text(
                                  'Source: ${c.title} (Reviewed: ${c.reviewedOn})',
                                  style: AppTypography.captionSmall.copyWith(
                                    color: AppColors.fieldSlate,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLadderSection({
    required String stepNumber,
    required String stepTitle,
    required String stepSubtitle,
    required Color accentColor,
    required List<LadderRung> rungs,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m12),
      decoration: BoxDecoration(
        color: AppColors.warmSurface,
        borderRadius: AppRadius.button,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    stepNumber,
                    style: AppTypography.captionSmall.copyWith(
                      color: AppColors.pureWhite,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stepTitle,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.soilCharcoal,
                      ),
                    ),
                    Text(
                      stepSubtitle,
                      style: AppTypography.captionSmall.copyWith(
                        color: AppColors.fieldSlate,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
          ...rungs.map(
            (rung) => Padding(
              padding: const EdgeInsets.only(left: 32, top: 4),
              child: Text(
                '• ${rung.action}',
                style: AppTypography.body.copyWith(
                  fontSize: 15,
                  color: AppColors.soilCharcoal,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChemicalSection(List<LadderRung> chemicalRungs) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.warmSurface,
        borderRadius: AppRadius.button,
        border: Border.all(
          color: _isChemicalExpanded ? AppColors.turmeric : AppColors.border,
          width: _isChemicalExpanded ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isChemicalExpanded = !_isChemicalExpanded;
              });
            },
            borderRadius: AppRadius.button,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.m12),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: AppColors.turmeric,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '3',
                        style: AppTypography.captionSmall.copyWith(
                          color: AppColors.pureWhite,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Chemical Action (रासायनिक फवारणी)',
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.soilCharcoal,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.warningBg,
                                borderRadius: AppRadius.chip,
                              ),
                              child: Text(
                                'Last Resort',
                                style: AppTypography.captionSmall.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.warning,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Strictly collapsed by default — use only if needed',
                          style: AppTypography.captionSmall.copyWith(
                            color: AppColors.fieldSlate,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isChemicalExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: AppColors.fieldSlate,
                  ),
                ],
              ),
            ),
          ),
          if (_isChemicalExpanded) ...[
            const Divider(height: 1, color: AppColors.subtleDivider),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.m12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: chemicalRungs.map((rung) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rung.action,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.soilCharcoal,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s8),
                      if (rung.dosage != null)
                        _buildChemicalDetailRow(
                          icon: Icons.water_drop_outlined,
                          label: 'Dosage (प्रमाण):',
                          value: rung.dosage!,
                        ),
                      if (rung.phiDays != null)
                        _buildChemicalDetailRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Pre-Harvest Interval (PHI):',
                          value: '${rung.phiDays} days before harvest',
                        ),
                      if (rung.reentryHours != null)
                        _buildChemicalDetailRow(
                          icon: Icons.timer_outlined,
                          label: 'Re-entry Period:',
                          value: '${rung.reentryHours} hours after spraying',
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChemicalDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.fieldSlate),
          const SizedBox(width: AppSpacing.s8),
          Text(
            label,
            style: AppTypography.captionSmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.fieldSlate,
            ),
          ),
          const SizedBox(width: AppSpacing.xs4),
          Expanded(
            child: Text(
              value,
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.soilCharcoal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
