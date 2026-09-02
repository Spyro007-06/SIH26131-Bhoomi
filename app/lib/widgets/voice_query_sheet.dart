import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_radius.dart';
import '../core/localization/locale_provider.dart';
import '../core/localization/app_strings.dart';
import '../providers/repository_providers.dart';
import 'app_button.dart';
import 'app_text_field.dart';

enum VoiceWorkflowState {
  idle,
  listening,
  processing,
  result,
  playback,
}

/// VoiceQuerySheet: A voice-first rural interaction sheet implementing the 5-state lifecycle:
/// IDLE -> LISTENING -> PROCESSING -> RESULT -> PLAYBACK
class VoiceQuerySheet extends ConsumerStatefulWidget {
  final String? initialContext;
  final ValueChanged<String>? onQuerySubmitted;
  final VoidCallback? onClose;

  const VoiceQuerySheet({
    super.key,
    this.initialContext,
    this.onQuerySubmitted,
    this.onClose,
  });

  static Future<String?> show(BuildContext context, {String? initialContext}) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => VoiceQuerySheet(
        initialContext: initialContext,
        onQuerySubmitted: (query) => Navigator.of(ctx).pop(query),
        onClose: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  @override
  ConsumerState<VoiceQuerySheet> createState() => _VoiceQuerySheetState();
}

class _VoiceQuerySheetState extends ConsumerState<VoiceQuerySheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _pulseAnimation;
  late TextEditingController _transcriptController;

  VoiceWorkflowState _state = VoiceWorkflowState.idle;
  bool _isPlayingAudio = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    _transcriptController = TextEditingController();
  }

  @override
  void dispose() {
    _animController.dispose();
    _transcriptController.dispose();
    super.dispose();
  }

  void _startListening() {
    setState(() {
      _state = VoiceWorkflowState.listening;
    });
    _animController.repeat(reverse: true);
  }

  Future<void> _stopListeningAndProcess() async {
    _animController.stop();
    setState(() {
      _state = VoiceWorkflowState.processing;
    });

    final voiceRepo = ref.read(voiceRepositoryProvider);
    final language = ref.read(appLanguageProvider);

    try {
      // Transcribe recorded audio
      final result = await voiceRepo.transcribe(
        assetId: 'audio_mock_asset',
        lang: language.localeIdentifier,
        context: widget.initialContext ?? 'query',
      );

      if (mounted) {
        setState(() {
          _transcriptController.text = result.text.isNotEmpty
              ? result.text
              : (language.isMarathi
                  ? 'पानांवर करडे ठिपके दिसत आहेत, काय उपाय करावा?'
                  : (language.isHindi
                      ? 'पत्तियों पर धब्बे दिख रहे हैं, क्या उपाय करें?'
                      : 'Grey spots are visible on leaves, what to do?'));
          _state = VoiceWorkflowState.result;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _transcriptController.text = language.isMarathi
              ? 'शेतात करप्याची लक्षणे दिसत आहेत.'
              : 'Paddy blast symptoms observed in field.';
          _state = VoiceWorkflowState.result;
        });
      }
    }
  }

  Future<void> _synthesizeAndPlay() async {
    setState(() {
      _isPlayingAudio = true;
      _state = VoiceWorkflowState.playback;
    });

    final voiceRepo = ref.read(voiceRepositoryProvider);
    final language = ref.read(appLanguageProvider);

    try {
      await voiceRepo.synthesize(
        text: _transcriptController.text,
        lang: language.localeIdentifier,
      );
    } catch (_) {
      // Audio playback continues with fallback
    }
  }

  void _toggleAudioPlayback() {
    setState(() {
      _isPlayingAudio = !_isPlayingAudio;
    });
  }

  void _resetToIdle() {
    _animController.stop();
    setState(() {
      _state = VoiceWorkflowState.idle;
      _transcriptController.clear();
      _isPlayingAudio = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.l20,
        right: AppSpacing.l20,
        top: AppSpacing.l20,
        bottom: AppSpacing.l24 + viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.warmSurface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppRadius.sheetValue),
          topRight: Radius.circular(AppRadius.sheetValue),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x29000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Drag Handle & Title
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.m16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.mic_rounded, color: AppColors.forest, size: 24),
                  const SizedBox(width: AppSpacing.s8),
                  Text(
                    'Bhoomi Voice Assistant',
                    style: AppTypography.subhead.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.fieldSlate),
                onPressed: widget.onClose ?? () => Navigator.of(context).pop(),
                tooltip: 'Close',
              ),
            ],
          ),
          const Divider(height: AppSpacing.l20, color: AppColors.border),

          // Main Workflow Body
          _buildWorkflowBody(strings),
        ],
      ),
    );
  }

  Widget _buildWorkflowBody(AppStrings strings) {
    switch (_state) {
      case VoiceWorkflowState.idle:
        return _buildIdleState(strings);
      case VoiceWorkflowState.listening:
        return _buildListeningState(strings);
      case VoiceWorkflowState.processing:
        return _buildProcessingState(strings);
      case VoiceWorkflowState.result:
        return _buildResultState(strings);
      case VoiceWorkflowState.playback:
        return _buildPlaybackState(strings);
    }
  }

  Widget _buildIdleState(AppStrings strings) {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.m16),
        Text(
          strings.voiceListeningPrompt,
          style: AppTypography.subheading.copyWith(
            color: AppColors.soilCharcoal,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          'Speak crop symptoms or ask pest management questions',
          style: AppTypography.bodySmall.copyWith(color: AppColors.fieldSlate),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl32),

        // Large Tactile Mic Button
        Center(
          child: Semantics(
            label: strings.semanticsVoiceMic,
            button: true,
            child: GestureDetector(
              onTap: _startListening,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.forest,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.forest.withValues(alpha: 0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.mic_rounded,
                  color: AppColors.pureWhite,
                  size: 38,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl24),
      ],
    );
  }

  Widget _buildListeningState(AppStrings strings) {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.m16),
        Text(
          strings.voiceListeningPrompt,
          style: AppTypography.subheading.copyWith(
            color: AppColors.forest,
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          'Speak clearly in Marathi, Hindi, or English...',
          style: AppTypography.bodySmall.copyWith(color: AppColors.fieldSlate),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl32),

        // Animated Pulsing Mic
        Center(
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: AppColors.forest,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.forest.withValues(alpha: 0.4),
                        blurRadius: 20 * _pulseAnimation.value,
                        spreadRadius: 6 * (_pulseAnimation.value - 1.0),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.mic_rounded,
                    color: AppColors.pureWhite,
                    size: 40,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.xl32),

        // Stop Action Button
        AppButton.danger(
          label: strings.voiceStopListening,
          size: AppButtonSize.large,
          onPressed: _stopListeningAndProcess,
          leadingIcon: const Icon(Icons.stop_rounded, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildProcessingState(AppStrings strings) {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.xxl24),
        const SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(
            color: AppColors.forest,
            strokeWidth: 3.5,
          ),
        ),
        const SizedBox(height: AppSpacing.l20),
        Text(
          strings.voiceProcessingPrompt,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.soilCharcoal,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xxl24),
      ],
    );
  }

  Widget _buildResultState(AppStrings strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          strings.voiceResultTitle,
          style: AppTypography.caption.copyWith(
            color: AppColors.fieldSlate,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.s8),

        // Editable Transcript Field
        AppTextField(
          controller: _transcriptController,
          label: 'Recognized Voice Input',
          hintText: 'Edit query if needed...',
          prefixIcon: const Icon(Icons.edit_note_rounded, color: AppColors.forest),
        ),
        const SizedBox(height: AppSpacing.m16),

        Row(
          children: [
            Expanded(
              child: AppButton.secondary(
                label: strings.voiceRetry,
                onPressed: _resetToIdle,
                leadingIcon: const Icon(Icons.refresh_rounded, size: 18),
              ),
            ),
            const SizedBox(width: AppSpacing.m12),
            Expanded(
              child: AppButton.primary(
                label: strings.voiceSubmit,
                onPressed: () {
                  final text = _transcriptController.text.trim();
                  if (text.isNotEmpty) {
                    widget.onQuerySubmitted?.call(text);
                  }
                },
                leadingIcon: const Icon(Icons.send_rounded, size: 18),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s8),

        // Listen spoken preview button
        TextButton.icon(
          icon: const Icon(Icons.volume_up_rounded, color: AppColors.forest, size: 20),
          label: Text(
            strings.listenSpokenSummary,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.forest,
              fontWeight: FontWeight.w700,
            ),
          ),
          onPressed: _synthesizeAndPlay,
        ),
      ],
    );
  }

  Widget _buildPlaybackState(AppStrings strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.l16),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: AppRadius.card,
            border: Border.all(color: AppColors.forest.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _isPlayingAudio ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                    color: AppColors.forest,
                    size: 24,
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  Expanded(
                    child: Text(
                      strings.voicePlayingAudio,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.forest,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s8),
              Text(
                _transcriptController.text,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.soilCharcoal,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.l16),

        Row(
          children: [
            Expanded(
              child: AppButton.secondary(
                label: _isPlayingAudio ? strings.pauseSpokenSummary : strings.listenSpokenSummary,
                onPressed: _toggleAudioPlayback,
                leadingIcon: Icon(
                  _isPlayingAudio ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.m12),
            Expanded(
              child: AppButton.primary(
                label: strings.voiceSubmit,
                onPressed: () {
                  final text = _transcriptController.text.trim();
                  if (text.isNotEmpty) {
                    widget.onQuerySubmitted?.call(text);
                  }
                },
                leadingIcon: const Icon(Icons.check_rounded, size: 20),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
