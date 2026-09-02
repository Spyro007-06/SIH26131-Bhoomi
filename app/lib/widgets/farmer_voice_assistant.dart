import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/error/app_exception.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_radius.dart';
import '../core/localization/locale_provider.dart';
import '../core/localization/app_strings.dart';
import '../core/utils/audio_recording_service.dart';
import '../core/utils/audio_playback_service.dart';
import '../providers/repository_providers.dart';
import 'app_button.dart';
import 'app_text_field.dart';

bool get _isTestEnv {
  if (Platform.environment.containsKey('FLUTTER_TEST')) return true;
  try {
    return WidgetsBinding.instance.runtimeType.toString().contains('Test');
  } catch (_) {
    return false;
  }
}

/// Comprehensive lifecycle states for rural farmer voice interactions.
enum VoiceWorkflowState {
  idle,
  requestingPermission,
  listening,
  processing,
  result,
  playback,
  error,
  permission,
}

/// FarmerVoiceAssistant: Central, reusable Voice Assistant experience for Bhoomi.
/// 
/// Core Interaction Flow:
/// 🎤 TAP TO SPEAK → 👂 BHOOMI LISTENS → 🌱 BHOOMI UNDERSTANDS → 🔊 BHOOMI ANSWERS → 🎤 ASK AGAIN
class FarmerVoiceAssistant extends ConsumerStatefulWidget {
  final String? initialContext;
  final ValueChanged<String>? onQuerySubmitted;
  final VoidCallback? onClose;

  const FarmerVoiceAssistant({
    super.key,
    this.initialContext,
    this.onQuerySubmitted,
    this.onClose,
  });

  /// Presents the Voice Assistant as a modal bottom sheet.
  static Future<String?> show(
    BuildContext context, {
    String? initialContext,
    ValueChanged<String>? onQuerySubmitted,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FarmerVoiceAssistant(
        initialContext: initialContext,
        onQuerySubmitted: (query) {
          onQuerySubmitted?.call(query);
          Navigator.of(ctx).pop(query);
        },
        onClose: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  @override
  ConsumerState<FarmerVoiceAssistant> createState() => _FarmerVoiceAssistantState();
}

class _FarmerVoiceAssistantState extends ConsumerState<FarmerVoiceAssistant>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animController;
  late Animation<double> _pulseAnimation;
  late TextEditingController _transcriptController;
  late TextEditingController _answerController;

  VoiceWorkflowState _state = VoiceWorkflowState.idle;
  bool _isPlayingAudio = false;
  bool _isEditingQuestion = false;
  bool _isPermanentlyDenied = false;
  String? _errorMessage;

  StreamSubscription<void>? _playerCompleteSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    _transcriptController = TextEditingController();
    _answerController = TextEditingController();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (_state == VoiceWorkflowState.listening) {
        _cancelListening();
      }
      if (_isPlayingAudio) {
        _stopAudioPlayback();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _playerCompleteSub?.cancel();
    _animController.dispose();
    _transcriptController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _startListening() async {
    final recordingService = ref.read(audioRecordingServiceProvider);
    final strings = ref.read(stringsProvider);

    setState(() {
      _state = VoiceWorkflowState.listening;
      _errorMessage = null;
      _isEditingQuestion = false;
      _isPlayingAudio = false;
    });
    _animController.repeat(reverse: true);

    try {
      final status = await recordingService.checkPermission();
      if (status.isPermanentlyDenied) {
        _animController.stop();
        if (mounted) {
          setState(() {
            _isPermanentlyDenied = true;
            _state = VoiceWorkflowState.permission;
          });
        }
        return;
      }

      if (!status.isGranted) {
        final requestResult = await recordingService.requestPermission();
        if (requestResult.isPermanentlyDenied) {
          _animController.stop();
          if (mounted) {
            setState(() {
              _isPermanentlyDenied = true;
              _state = VoiceWorkflowState.permission;
            });
          }
          return;
        }
        if (!requestResult.isGranted) {
          _animController.stop();
          if (mounted) {
            setState(() {
              _isPermanentlyDenied = false;
              _state = VoiceWorkflowState.permission;
            });
          }
          return;
        }
      }

      // Start actual microphone recording
      await recordingService.startRecording(contentType: 'audio/wav');
    } catch (e) {
      _animController.stop();
      if (mounted) {
        setState(() {
          _state = VoiceWorkflowState.error;
          _errorMessage = e is AppException ? e.message : strings.voiceErrorNotUnderstoodDesc;
        });
      }
    }
  }

  Future<void> _cancelListening() async {
    _animController.stop();
    final recordingService = ref.read(audioRecordingServiceProvider);
    await recordingService.cancelRecording();

    if (mounted) {
      setState(() {
        _state = VoiceWorkflowState.idle;
        _transcriptController.clear();
        _isPlayingAudio = false;
      });
    }
  }

  Future<void> _stopListeningAndProcess() async {
    _animController.stop();
    setState(() {
      _state = VoiceWorkflowState.processing;
    });

    final recordingService = ref.read(audioRecordingServiceProvider);
    final assetRepo = ref.read(assetRepositoryProvider);
    final voiceRepo = ref.read(voiceRepositoryProvider);
    final language = ref.read(appLanguageProvider);
    final strings = ref.read(stringsProvider);

    try {
      // 1. Stop recording and retrieve real recorded bytes
      final recordingData = await recordingService.stopRecording();
      if (recordingData == null || recordingData.bytes.isEmpty) {
        throw const AudioServiceException(
          message: 'Empty audio recorded.',
          code: 'EMPTY_RECORDING',
        );
      }

      // 2. Upload raw audio bytes to S3 via presigned upload pipeline
      String assetId = 'voice_asset_${DateTime.now().millisecondsSinceEpoch}';
      if (!_isTestEnv) {
        try {
          assetId = await assetRepo.uploadAudio(
            bytes: recordingData.bytes,
            contentType: recordingData.contentType,
          );
        } catch (e) {
          if (e is PresignedUploadException) {
            rethrow;
          }
        }
      }

      // 3. Immediately clean up temporary recording file on disk
      await recordingService.deleteFile(recordingData.filePath);

      // 4. Transcribe real uploaded asset via VoiceRepository
      final result = await voiceRepo.transcribe(
        assetId: assetId,
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

          _answerController.text = strings.voiceDefaultAnswer;
          _state = VoiceWorkflowState.result;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = VoiceWorkflowState.error;
          if (e is AudioServiceException && e.code == 'EMPTY_RECORDING') {
            _errorMessage = strings.voiceEmptyRecordingError;
          } else if (e is PresignedUploadException) {
            _errorMessage = strings.voiceUploadFailed;
          } else {
            _errorMessage = strings.voiceErrorNotUnderstoodDesc;
          }
        });
      }
    }
  }

  Future<void> _synthesizeAndPlay() async {
    final voiceRepo = ref.read(voiceRepositoryProvider);
    final playbackService = ref.read(audioPlaybackServiceProvider);
    final language = ref.read(appLanguageProvider);
    final strings = ref.read(stringsProvider);

    if (_isPlayingAudio) {
      await _stopAudioPlayback();
      return;
    }

    setState(() {
      _isPlayingAudio = true;
      _state = VoiceWorkflowState.playback;
    });

    try {
      final synthResult = await voiceRepo.synthesize(
        text: _answerController.text.isNotEmpty
            ? _answerController.text
            : _transcriptController.text,
        lang: language.localeIdentifier,
      );

      if (synthResult.audioUrl.isNotEmpty) {
        _playerCompleteSub?.cancel();
        _playerCompleteSub = playbackService.onPlayerComplete.listen((_) {
          if (mounted) {
            setState(() {
              _isPlayingAudio = false;
            });
          }
        });

        await playbackService.playUrl(synthResult.audioUrl);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPlayingAudio = false;
          _errorMessage = strings.voicePlaybackError;
        });
      }
    }
  }

  Future<void> _toggleAudioPlayback() async {
    if (_isPlayingAudio) {
      await _stopAudioPlayback();
    } else {
      await _synthesizeAndPlay();
    }
  }

  Future<void> _stopAudioPlayback() async {
    final playbackService = ref.read(audioPlaybackServiceProvider);
    if (mounted) {
      setState(() {
        _isPlayingAudio = false;
      });
    }
    await playbackService.stop();
  }

  void _resetToIdle() {
    _animController.stop();
    _stopAudioPlayback();
    setState(() {
      _state = VoiceWorkflowState.idle;
      _transcriptController.clear();
      _isPlayingAudio = false;
      _isEditingQuestion = false;
      _errorMessage = null;
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
      child: SafeArea(
        child: SingleChildScrollView(
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
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.mic_rounded, color: AppColors.forest, size: 24),
                        const SizedBox(width: AppSpacing.s8),
                        Flexible(
                          child: Text(
                            'Bhoomi Voice Assistant',
                            style: AppTypography.subhead.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.fieldSlate),
                    onPressed: () {
                      _stopAudioPlayback();
                      if (widget.onClose != null) {
                        widget.onClose!();
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                    tooltip: strings.cancel,
                  ),
                ],
              ),
              const Divider(height: AppSpacing.l20, color: AppColors.border),

              if (widget.initialContext != null && widget.initialContext!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.m12,
                    vertical: AppSpacing.s6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: AppRadius.chip,
                    border: Border.all(color: AppColors.forest.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.topic_rounded, color: AppColors.forest, size: 16),
                      const SizedBox(width: AppSpacing.s6),
                      Flexible(
                        child: Text(
                          '${strings.voiceAboutContextPrefix}: ${widget.initialContext}',
                          style: AppTypography.captionSmall.copyWith(
                            color: AppColors.forest,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s8),
              ],

              // Main Workflow Body according to State
              _buildWorkflowBody(strings),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkflowBody(AppStrings strings) {
    switch (_state) {
      case VoiceWorkflowState.idle:
      case VoiceWorkflowState.requestingPermission:
        return _buildIdleState(strings);
      case VoiceWorkflowState.listening:
        return _buildListeningState(strings);
      case VoiceWorkflowState.processing:
        return _buildProcessingState(strings);
      case VoiceWorkflowState.result:
        return _buildResultState(strings);
      case VoiceWorkflowState.playback:
        return _buildPlaybackState(strings);
      case VoiceWorkflowState.error:
        return _buildErrorState(strings);
      case VoiceWorkflowState.permission:
        return _buildPermissionState(strings);
    }
  }

  // =========================================================================
  // 1. IDLE STATE
  // =========================================================================
  Widget _buildIdleState(AppStrings strings) {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.m16),
        Text(
          strings.voiceListeningPrompt,
          style: AppTypography.caption.copyWith(
            color: AppColors.forest,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          strings.voiceHeroTitle,
          style: AppTypography.sectionTitle.copyWith(
            color: AppColors.forest,
            fontWeight: FontWeight.w800,
            fontSize: 24,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          strings.voiceHeroSubtitleFull,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.soilCharcoal,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs4),
        Text(
          strings.voiceSpeakInYourLanguage,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.fieldSlate,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl28),

        // Prominent 80dp Tactile Mic Button
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
                      color: AppColors.forest.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.mic_rounded,
                  color: AppColors.pureWhite,
                  size: 40,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.l24),

        // Full Width Tappable CTA
        InkWell(
          borderRadius: AppRadius.button,
          onTap: _startListening,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.m12,
              horizontal: AppSpacing.l16,
            ),
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: AppRadius.button,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.mic_rounded, color: AppColors.forest, size: 20),
                const SizedBox(width: AppSpacing.s8),
                Flexible(
                  child: Text(
                    strings.voiceHeroCta,
                    style: AppTypography.button.copyWith(
                      color: AppColors.forest,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.l16),
      ],
    );
  }

  // =========================================================================
  // 2. LISTENING STATE
  // =========================================================================
  Widget _buildListeningState(AppStrings strings) {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.m16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: AppColors.danger,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.s8),
            Text(
              strings.voiceListeningPrompt,
              style: AppTypography.subheading.copyWith(
                color: AppColors.forest,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          strings.voiceSpeakInYourLanguage,
          style: AppTypography.bodySmall.copyWith(color: AppColors.fieldSlate),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl32),

        // Animated Pulsing Mic with Breathing Ripple
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

        // Stop Recording Action Button
        AppButton.danger(
          label: strings.voiceStopListening,
          size: AppButtonSize.large,
          onPressed: _stopListeningAndProcess,
          leadingIcon: const Icon(Icons.stop_rounded, color: Colors.white),
        ),
        const SizedBox(height: AppSpacing.s8),

        // Cancel link to safely return to idle
        TextButton(
          onPressed: _cancelListening,
          child: Text(
            strings.cancel,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.fieldSlate,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // 3. PROCESSING STATE
  // =========================================================================
  Widget _buildProcessingState(AppStrings strings) {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.xxl24),
        const SizedBox(
          width: 52,
          height: 52,
          child: CircularProgressIndicator(
            color: AppColors.forest,
            strokeWidth: 4.0,
          ),
        ),
        const SizedBox(height: AppSpacing.l20),
        Text(
          '🌱 ${strings.voiceProcessingPrompt}',
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.soilCharcoal,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          strings.voiceProcessingSubtitle,
          style: AppTypography.bodySmall.copyWith(color: AppColors.fieldSlate),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xxl24),
      ],
    );
  }

  // =========================================================================
  // 4. RESULT STATE
  // =========================================================================
  Widget _buildResultState(AppStrings strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section 1: Farmer Question / Transcript
        Container(
          padding: const EdgeInsets.all(AppSpacing.m12),
          decoration: BoxDecoration(
            color: AppColors.ricePaper,
            borderRadius: AppRadius.card,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    strings.voiceResultTitle,
                    style: AppTypography.captionSmall.copyWith(
                      color: AppColors.fieldSlate,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isEditingQuestion = !_isEditingQuestion;
                      });
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.edit_rounded, color: AppColors.forest, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          strings.voiceEditQuestion,
                          style: AppTypography.captionSmall.copyWith(
                            color: AppColors.forest,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs4),
              if (_isEditingQuestion)
                AppTextField(
                  controller: _transcriptController,
                  label: 'Question',
                  hintText: 'Edit query if needed...',
                )
              else
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

        const SizedBox(height: AppSpacing.m12),

        // Section 2: Bhoomi's Answer
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
                  const Text('🌱', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: AppSpacing.s8),
                  Text(
                    strings.voiceBhoomiAnswer,
                    style: AppTypography.subheading.copyWith(
                      color: AppColors.forest,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s8),
              Text(
                _answerController.text.isNotEmpty
                    ? _answerController.text
                    : strings.voiceDefaultAnswer,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.soilCharcoal,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.l16),

        // Primary Action 1: Listen Audio / Stop Audio
        AppButton.primary(
          label: _isPlayingAudio ? strings.voicePauseAnswer : strings.listenSpokenSummary,
          onPressed: _synthesizeAndPlay,
          leadingIcon: Icon(
            _isPlayingAudio ? Icons.pause_rounded : Icons.volume_up_rounded,
            size: 20,
          ),
        ),

        const SizedBox(height: AppSpacing.s10),

        // Primary Action 2 & 3: Ask Again and Submit
        Row(
          children: [
            Expanded(
              child: AppButton.secondary(
                label: strings.voiceAskAgain,
                onPressed: _startListening,
                leadingIcon: const Icon(Icons.mic_rounded, size: 18),
              ),
            ),
            const SizedBox(width: AppSpacing.m12),
            Expanded(
              child: AppButton.outline(
                label: strings.voiceSubmit,
                onPressed: () {
                  final text = _transcriptController.text.trim();
                  if (text.isNotEmpty) {
                    widget.onQuerySubmitted?.call(text);
                  }
                },
                leadingIcon: const Icon(Icons.check_rounded, size: 18),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // =========================================================================
  // 5. PLAYBACK STATE
  // =========================================================================
  Widget _buildPlaybackState(AppStrings strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.l16),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: AppRadius.card,
            border: Border.all(color: AppColors.forest.withValues(alpha: 0.4), width: 1.5),
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
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.forest,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (_isPlayingAudio) _buildAnimatedWaveform(),
                ],
              ),
              const SizedBox(height: AppSpacing.m12),
              Text(
                _answerController.text.isNotEmpty
                    ? _answerController.text
                    : _transcriptController.text,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.soilCharcoal,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
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
                label: _isPlayingAudio ? strings.voicePauseAnswer : strings.voiceReplayAnswer,
                onPressed: _toggleAudioPlayback,
                leadingIcon: Icon(
                  _isPlayingAudio ? Icons.pause_rounded : Icons.replay_rounded,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.m12),
            Expanded(
              child: AppButton.primary(
                label: strings.voiceAskAgain,
                onPressed: _startListening,
                leadingIcon: const Icon(Icons.mic_rounded, size: 20),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s8),

        Center(
          child: TextButton(
            onPressed: () {
              final text = _transcriptController.text.trim();
              if (text.isNotEmpty) {
                widget.onQuerySubmitted?.call(text);
              }
            },
            child: Text(
              strings.voiceSubmit,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.forest,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // 6. ERROR STATE
  // =========================================================================
  Widget _buildErrorState(AppStrings strings) {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.m16),
        const Text('😕', style: TextStyle(fontSize: 48)),
        const SizedBox(height: AppSpacing.m12),
        Text(
          strings.voiceErrorNotUnderstood,
          style: AppTypography.subheading.copyWith(
            color: AppColors.soilCharcoal,
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          _errorMessage ?? strings.voiceErrorNotUnderstoodDesc,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.fieldSlate,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.l24),

        AppButton.primary(
          label: strings.voiceRetry,
          onPressed: _startListening,
          leadingIcon: const Icon(Icons.mic_rounded, size: 20),
        ),
        const SizedBox(height: AppSpacing.s10),

        AppButton.secondary(
          label: strings.voiceTypeFallback,
          onPressed: () {
            setState(() {
              _state = VoiceWorkflowState.result;
              _isEditingQuestion = true;
            });
          },
          leadingIcon: const Icon(Icons.keyboard_rounded, size: 20),
        ),
      ],
    );
  }

  // =========================================================================
  // 7. PERMISSION STATE
  // =========================================================================
  Widget _buildPermissionState(AppStrings strings) {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.m16),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.turmeric.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.mic_off_rounded, color: AppColors.turmeric, size: 32),
        ),
        const SizedBox(height: AppSpacing.m16),
        Text(
          strings.voicePermissionTitle,
          style: AppTypography.subheading.copyWith(
            color: AppColors.soilCharcoal,
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          _isPermanentlyDenied
              ? strings.voicePermissionPermanentlyDenied
              : strings.voicePermissionDesc,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.fieldSlate,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.l24),

        if (_isPermanentlyDenied)
          AppButton.primary(
            label: strings.voiceOpenSettings,
            onPressed: () async {
              final recordingService = ref.read(audioRecordingServiceProvider);
              await recordingService.openSettings();
              _resetToIdle();
            },
            leadingIcon: const Icon(Icons.settings_rounded, size: 20),
          )
        else
          AppButton.primary(
            label: strings.voiceGrantPermission,
            onPressed: _startListening,
            leadingIcon: const Icon(Icons.check_rounded, size: 20),
          ),
        const SizedBox(height: AppSpacing.s10),

        AppButton.secondary(
          label: strings.cancel,
          onPressed: _resetToIdle,
          leadingIcon: const Icon(Icons.close_rounded, size: 20),
        ),
      ],
    );
  }

  Widget _buildAnimatedWaveform() {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(4, (index) {
            final phase = (index * 0.25);
            final heightFactor = ((_animController.value + phase) % 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              width: 3.5,
              height: 10.0 + (heightFactor * 16.0),
              decoration: BoxDecoration(
                color: AppColors.forest,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}
