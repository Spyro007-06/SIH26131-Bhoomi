import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_section_header.dart';
import '../../widgets/app_loading.dart';
import '../../widgets/app_error_state.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/stub_banner.dart';
import '../../widgets/voice_action_button.dart';
import '../../widgets/farm_health_card.dart';
import '../../widgets/risk_card.dart';
import '../../widgets/confidence_gate_card.dart';
import '../../widgets/advisory_ipm_card.dart';
import '../../widgets/pesticide_veto_card.dart';
import '../../widgets/followup_card.dart';

/// Design Showcase & Visual Preview Screen for Bhoomi Farmer App.
///
/// Contains all 11 required design components to validate the visual language,
/// typography in Devanagari, outdoor contrast, and UX invariants before production.
class DesignShowcaseScreen extends StatefulWidget {
  const DesignShowcaseScreen({super.key});

  @override
  State<DesignShowcaseScreen> createState() => _DesignShowcaseScreenState();
}

class _DesignShowcaseScreenState extends State<DesignShowcaseScreen> {
  String _selectedLocale = 'mr-IN';
  VoiceState _voiceState = VoiceState.idle;
  int _selectedGateIndex = 0; // 0: Advise, 1: Clarify, 2: Escalate
  String _selectedVerdict = 'WRONG_CLASS';
  String? _doubtDoctorAnswer;
  String? _followupAnswer;
  final TextEditingController _inputController = TextEditingController(
    text: 'पानांवर करडे ठिपके दिसत आहेत',
  );

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _cycleVoiceState() {
    setState(() {
      switch (_voiceState) {
        case VoiceState.idle:
          _voiceState = VoiceState.listening;
          break;
        case VoiceState.listening:
          _voiceState = VoiceState.transcribing;
          break;
        case VoiceState.transcribing:
          _voiceState = VoiceState.playback;
          break;
        case VoiceState.playback:
          _voiceState = VoiceState.idle;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ricePaper,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.eco_rounded, color: AppColors.forest, size: 26),
            SizedBox(width: AppSpacing.s8),
            Flexible(
              child: Text(
                'Bhoomi Design System',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          // Language Switcher
          Container(
            margin: const EdgeInsets.only(right: AppSpacing.l16),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8),
            decoration: BoxDecoration(
              color: AppColors.warmSurface,
              borderRadius: AppRadius.chip,
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedLocale,
                icon: const Icon(Icons.language_rounded, size: 18, color: AppColors.forest),
                style: AppTypography.captionSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.soilCharcoal,
                ),
                items: const [
                  DropdownMenuItem(value: 'mr-IN', child: Text('मराठी (mr-IN)')),
                  DropdownMenuItem(value: 'hi-IN', child: Text('हिन्दी (hi-IN)')),
                  DropdownMenuItem(value: 'en-IN', child: Text('English (en-IN)')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedLocale = val);
                  }
                },
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.pagePadding,
          children: [
            // Subtitle banner explaining the purpose
            Container(
              padding: const EdgeInsets.all(AppSpacing.m12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: AppRadius.card,
                border: Border.all(color: AppColors.forest.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.palette_outlined, color: AppColors.forest, size: 22),
                  const SizedBox(width: AppSpacing.s8),
                  Expanded(
                    child: Text(
                      'Bhoomi v2 UI Showcase: Validating visual tokens, touch targets, and frozen UX rules.',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.l16),

            // ===============================================================
            // 6. STUB BANNER (Demonstration Mode)
            // ===============================================================
            const AppSectionHeader(
              title: '6. Demonstration Stub Mode Banner',
              subtitle: 'Mandatory Invariant 11: Rendered visibly whenever is_stub == true',
              icon: Icon(Icons.science_rounded),
            ),
            const StubBanner(),

            // ===============================================================
            // 1, 2, 3. BUTTONS (Primary, Secondary, Danger, Outline)
            // ===============================================================
            const AppSectionHeader(
              title: '1, 2, 3. Action Buttons & Touch Targets',
              subtitle: '48–56px tactile height, high contrast for bright outdoor sunlight',
              icon: Icon(Icons.touch_app_rounded),
            ),
            Wrap(
              spacing: AppSpacing.m12,
              runSpacing: AppSpacing.m12,
              children: [
                // 1. Primary Button
                AppButton.primary(
                  label: '1. Primary Button (मुख्य बटण)',
                  onPressed: () {},
                  leadingIcon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                ),
                // 2. Secondary Button
                AppButton.secondary(
                  label: '2. Secondary Button (दुय्यम बटण)',
                  onPressed: () {},
                  leadingIcon: const Icon(Icons.spa_outlined, size: 20),
                ),
                // 3. Danger Button
                AppButton.danger(
                  label: '3. Danger Button (धोका / थांबवा)',
                  onPressed: () {},
                  leadingIcon: const Icon(Icons.warning_amber_rounded, size: 20),
                ),
                // Outline Button
                AppButton.outline(
                  label: 'Outline Action',
                  onPressed: () {},
                ),
                // Loading State Button
                AppButton.primary(
                  label: 'Analyzing...',
                  isLoading: true,
                  onPressed: () {},
                ),
              ],
            ),

            // ===============================================================
            // 8. INPUT FIELD (AppTextField)
            // ===============================================================
            const AppSectionHeader(
              title: '8. Tactile Input Field',
              subtitle: 'Large 14px radius, >=16px text, integrated voice mic trigger',
              icon: Icon(Icons.edit_note_rounded),
            ),
            AppTextField(
              controller: _inputController,
              label: 'Observed Crop Symptoms (पिकावरील लक्षणे)',
              hintText: 'Describe or speak what you see in the field...',
              helperText: 'You can type or tap the microphone to speak in Marathi/Hindi.',
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.forest),
              onVoicePressed: () {
                setState(() {
                  _voiceState = VoiceState.listening;
                });
              },
            ),

            // ===============================================================
            // 9. VOICE ACTION BUTTON (First-Class Voice Interaction)
            // ===============================================================
            AppSectionHeader(
              title: '9. Voice Action Control (Voice-First)',
              subtitle: 'Tap the button below to cycle through the 4 voice states',
              icon: const Icon(Icons.mic_rounded),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: AppRadius.chip,
                ),
                child: Text(
                  'State: ${_voiceState.name.toUpperCase()}',
                  style: AppTypography.captionSmall.copyWith(
                    color: AppColors.forest,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            VoiceActionButton(
              state: _voiceState,
              spokenSummaryText: 'शेतात करप्याची सुरुवातीची लक्षणे दिसत आहेत. पाणी काढून शेत कोरडे करा.',
              onStartListening: _cycleVoiceState,
              onStopListening: _cycleVoiceState,
              onTogglePlayback: _cycleVoiceState,
            ),

            // ===============================================================
            // 4. FARM HEALTH CARD (Home Screen Centrepiece)
            // ===============================================================
            const AppSectionHeader(
              title: '4. Farm Health Card',
              subtitle: 'Farm identity + qualitative sentence + trend (F1, F11)',
              icon: Icon(Icons.home_outlined),
            ),
            FarmHealthCard(
              farmName: 'Indrayani Paddy Field (माझे भात शेत)',
              cropDetails: 'Paddy · Tillering Stage',
              region: 'Nashik, Maharashtra',
              healthSentence: 'One open problem, being monitored.',
              healthTrend: 'worsening',
              openProblems: 1,
              pendingFollowups: 1,
              activeAlerts: 1,
              onCheckCrop: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening Crop Camera Diagnosis...')),
                );
              },
              onAskBhoomi: () {
                setState(() => _voiceState = VoiceState.listening);
              },
            ),

            // ===============================================================
            // 5. ALERT CARD (RiskCard with non-nullable inspection task)
            // ===============================================================
            const AppSectionHeader(
              title: '5. Risk Alert Card',
              subtitle: 'Non-dismissible: Every alert carries at least one inspection task (F5)',
              icon: Icon(Icons.notification_important_rounded),
            ),
            RiskCard(
              target: 'Paddy Blast Warning (भातावरील करपा संभाव्य धोका)',
              riskLevel: 'high',
              triggerType: 'weather',
              reason: 'Night humidity above 92% and temperature 22–26°C for 4 consecutive nights at tillering stage.',
              inspectionTasks: const [
                'Check the upper leaves on 10 random plants across the field.',
                'Look for diamond-shaped spots with grey centres and take a photo.',
              ],
              onInspectNow: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Action recorded: Farmer is checking field.")),
                );
              },
              onRemindTomorrow: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Alert snoozed until tomorrow.")),
                );
              },
            ),

            // ===============================================================
            // 7. CONFIDENCE GATE CARDS (Advise, Clarify, Escalate)
            // ===============================================================
            AppSectionHeader(
              title: '7. Confidence Gate UI (3 Bands)',
              subtitle: 'Deterministic gate outcome: Advise, Clarify (Doubt Doctor), Escalate (F2, F4, F12)',
              icon: const Icon(Icons.call_split_rounded),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildGateTabButton('Advise', 0, AppColors.forest),
                  const SizedBox(width: 4),
                  _buildGateTabButton('Clarify', 1, AppColors.turmeric),
                  const SizedBox(width: 4),
                  _buildGateTabButton('Escalate', 2, AppColors.danger),
                ],
              ),
            ),

            if (_selectedGateIndex == 0)
              ConfidenceGateCard.advise(
                topDiagnosis: 'Paddy Blast (भातावरील करपा)',
                confidence: 0.87,
                alternatives: const [
                  PredictionItem(label: 'blast', confidence: 0.87, displayName: 'Paddy Blast (करपा)'),
                  PredictionItem(label: 'brown_spot', confidence: 0.09, displayName: 'Brown Spot (तपकिरी ठिपके)'),
                  PredictionItem(label: 'bacterial_leaf_blight', confidence: 0.04, displayName: 'Bacterial Leaf Blight (BLB)'),
                ],
                onViewAdvisory: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Scrolling to Advisory Ladder...')),
                  );
                },
              )
            else if (_selectedGateIndex == 1)
              ConfidenceGateCard.clarify(
                question: 'Flip the leaf over. Do you see fuzzy grey growth on the underside?',
                questionLocalized: 'पान उलटून पहा. पानाच्या खालच्या बाजूस करडी बुरशी दिसते का?',
                candidates: const [
                  CandidateSignature(
                    label: 'blast',
                    name: 'Paddy Blast (करपा)',
                    visualSignature: 'Diamond-shaped spindle lesions with grey ash centre and brown margin.',
                  ),
                  CandidateSignature(
                    label: 'brown_spot',
                    name: 'Brown Spot (तपकिरी ठिपके)',
                    visualSignature: 'Circular to oval brown lesions with distinct yellow halo.',
                  ),
                ],
                onAnswerSelected: (ans) {
                  setState(() => _doubtDoctorAnswer = ans);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Farmer observed: ${ans.toUpperCase()}')),
                  );
                },
              )
            else
              ConfidenceGateCard.escalate(
                reasonCode: 'BELOW_FLOOR',
                reasonDescription: 'Image confidence (31%) is below the minimum safety threshold (45%). Expert diagnosis required.',
                assignedTo: 'Dr. Patil, Agronomist (KVK Nashik)',
                queuePosition: 3,
                etaMinutes: 45,
                onCallHelpline: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Dialing Kisan Call Centre: 1800-180-1551')),
                  );
                },
              ),

            if (_doubtDoctorAnswer != null && _selectedGateIndex == 1) ...[
              const SizedBox(height: AppSpacing.s8),
              Text(
                'Recorded Observation: $_doubtDoctorAnswer (Travels into Case Bundle)',
                style: AppTypography.caption.copyWith(
                  color: AppColors.forest,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],

            // ===============================================================
            // 10. ADVISORY IPM CARD (Cultural -> Biological -> Chemical collapsed)
            // ===============================================================
            const AppSectionHeader(
              title: '10. Grounded Advisory with IPM Ladder',
              subtitle: 'Chemical last structurally. What to avoid first and loudest (F7)',
              icon: Icon(Icons.format_list_numbered_rounded),
            ),
            const AdvisoryIpmCard(),

            // ===============================================================
            // 11. PESTICIDE VETO CARD (Safety-critical label check)
            // ===============================================================
            AppSectionHeader(
              title: '11. Pesticide Label Check (Veto Check)',
              subtitle: 'Veto, never endorse. Verbatim strings. Never says "safe" (F8)',
              icon: const Icon(Icons.health_and_safety_outlined),
              trailing: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedVerdict,
                  items: const [
                    DropdownMenuItem(value: 'WRONG_CLASS', child: Text('Wrong Class')),
                    DropdownMenuItem(value: 'NO_OBJECTION_FOUND', child: Text('No Objection')),
                    DropdownMenuItem(value: 'WRONG_CROP', child: Text('Wrong Crop')),
                    DropdownMenuItem(value: 'NOT_REGISTERED_FOR_TARGET', child: Text('Not Registered')),
                    DropdownMenuItem(value: 'NOT_IN_RECORDS', child: Text('Not in Records')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedVerdict = val);
                  },
                ),
              ),
            ),
            PesticideVetoCard(
              activeIngredient: _selectedVerdict == 'WRONG_CLASS' ? 'carbendazim' : 'tricyclazole',
              concentration: '50% WP',
              formulation: 'wettable powder',
              ocrConfidence: 0.88,
              verdictCode: _selectedVerdict,
              onRetakePhoto: () {},
              onAskExpert: () {},
            ),

            // ===============================================================
            // EXTRA: FOLLOW-UP CHECK-IN CARD (F10)
            // ===============================================================
            const AppSectionHeader(
              title: 'Closed-Loop Follow-up Check-in (F10)',
              subtitle: '3-choice human check: Improved / No change / Got worse',
              icon: Icon(Icons.repeat_rounded),
            ),
            FollowUpCard(
              onResponse: (resp) {
                setState(() => _followupAnswer = resp);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Follow-up recorded: $resp')),
                );
              },
              onAttachPhoto: () {},
            ),

            if (_followupAnswer != null) ...[
              const SizedBox(height: AppSpacing.s8),
              Text(
                'Follow-up Outcome: $_followupAnswer (Updates case severity)',
                style: AppTypography.caption.copyWith(
                  color: AppColors.forest,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],

            // ===============================================================
            // EXTRA: LOADING, ERROR, EMPTY STATES
            // ===============================================================
            const AppSectionHeader(
              title: 'Feedback States (Loading, Error, Empty)',
              subtitle: 'Calm, non-jarring feedback for field conditions',
              icon: Icon(Icons.sync_rounded),
            ),
            const AppLoading(message: 'Analyzing leaf photograph with Confidence Gate...'),
            const SizedBox(height: AppSpacing.l16),
            AppErrorState(
              title: 'Intermittent Connectivity (इंटरनेट समस्या)',
              message: 'Unable to reach the agronomist server. Your photo and observations are safely stored offline.',
              onRetry: () {},
              onCallHelpline: () {},
            ),
            const SizedBox(height: AppSpacing.l16),
            AppEmptyState(
              title: 'No Active Field Issues (कोणतीही समस्या नाही)',
              description: 'Your paddy crop is currently healthy. Check back for seasonal weather alerts.',
              actionLabel: 'Take Preventative Photo',
              onAction: () {},
            ),

            const SizedBox(height: AppSpacing.huge40),
          ],
        ),
      ),
    );
  }

  Widget _buildGateTabButton(String label, int index, Color color) {
    final isSelected = _selectedGateIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedGateIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? color : AppColors.warmSurface,
          borderRadius: AppRadius.chip,
          border: Border.all(color: color),
        ),
        child: Text(
          label,
          style: AppTypography.captionSmall.copyWith(
            color: isSelected ? AppColors.pureWhite : color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
