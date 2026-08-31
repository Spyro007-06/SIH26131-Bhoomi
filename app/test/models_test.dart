import 'package:flutter_test/flutter_test.dart';
import 'package:bhoomi/models/auth_models.dart';
import 'package:bhoomi/models/farm_models.dart';
import 'package:bhoomi/models/gate_models.dart';
import 'package:bhoomi/models/advisory_models.dart';
import 'package:bhoomi/models/label_check_models.dart';
import 'package:bhoomi/models/alert_models.dart';
import 'package:bhoomi/models/problem_models.dart';
import 'package:bhoomi/models/followup_models.dart';
import 'package:bhoomi/models/timeline_models.dart';
import 'package:bhoomi/models/referral_models.dart';
import 'package:bhoomi/models/asset_models.dart';
import 'package:bhoomi/models/voice_models.dart';
import 'package:bhoomi/models/health_models.dart';

void main() {
  group('Wire Models Serialization & Deserialization Tests', () {
    test('Auth models serialization', () {
      final userJson = {
        'id': 'u_123',
        'phone': '+919876543210',
        'role': 'farmer',
      };
      final user = UserModel.fromJson(userJson);
      expect(user.id, 'u_123');
      expect(user.phone, '+919876543210');
      expect(user.role, 'farmer');
      expect(user.toJson(), userJson);

      final tokenJson = {
        'access_token': 'jwt_access_token_xyz',
        'refresh_token': 'jwt_refresh_token_abc',
        'expires_in': 3600,
      };
      final tokens = TokenPair.fromJson(tokenJson);
      expect(tokens.accessToken, 'jwt_access_token_xyz');
      expect(tokens.refreshToken, 'jwt_refresh_token_abc');
      expect(tokens.expiresIn, 3600);
      expect(tokens.toJson(), tokenJson);

      final otpVerifyJson = {
        'access_token': 'access_123',
        'refresh_token': 'refresh_123',
        'user': userJson,
      };
      final otpVerify = OtpVerifyResponse.fromJson(otpVerifyJson);
      expect(otpVerify.accessToken, 'access_123');
      expect(otpVerify.user.id, 'u_123');
      expect(otpVerify.toJson(), otpVerifyJson);
    });

    test('Farm models serialization', () {
      final farmJson = {
        'id': 'f_1',
        'crop': 'paddy',
        'variety': 'Indrayani',
        'growth_stage': 'tillering',
        'region': 'Nashik',
        'location': {'lat': 19.9975, 'lng': 73.7898},
      };
      final farm = FarmModel.fromJson(farmJson);
      expect(farm.id, 'f_1');
      expect(farm.crop, 'paddy');
      expect(farm.growthStage, 'tillering');
      expect(farm.location?.lat, 19.9975);
      expect(farm.location?.lng, 73.7898);

      final summaryJson = {
        'farm': farmJson,
        'health': {
          'sentence': 'One open problem, being monitored.',
          'trend': 'worsening'
        },
        'open_problems': 1,
        'pending_followups': 1,
        'active_alerts': 1,
        'spoken_summary': 'एक समस्या सुरू आहे...',
      };
      final summary = FarmSummaryModel.fromJson(summaryJson);
      expect(summary.farm.id, 'f_1');
      expect(summary.health.sentence, 'One open problem, being monitored.');
      expect(summary.health.trend, 'worsening');
      expect(summary.openProblems, 1);
      expect(summary.pendingFollowups, 1);
      expect(summary.activeAlerts, 1);
    });

    test('Gate and Prediction models serialization', () {
      final gateJson = {
        'outcome': 'advise',
        'confidence': 0.87,
        'threshold_applied': 0.70,
        'reason_code': 'ABOVE_GATE',
        'alternatives': [
          {'label': 'blast', 'confidence': 0.87},
          {'label': 'brown_spot', 'confidence': 0.09},
          {'label': 'bacterial_leaf_blight', 'confidence': 0.04},
        ],
        'is_stub': false,
      };
      final gate = GateDecision.fromJson(gateJson);
      expect(gate.outcome, 'advise');
      expect(gate.isAdvise, isTrue);
      expect(gate.isClarify, isFalse);
      expect(gate.isEscalate, isFalse);
      expect(gate.alternatives.length, 3);
      expect(gate.alternatives[0].label, 'blast');
      expect(gate.alternatives[0].confidence, 0.87);
    });

    test('Advisory and IPM Ladder models serialization', () {
      final advisoryJson = {
        'possible_issue': 'Early blast (confidence: high).',
        'what_to_check': 'Diamond-shaped lesions with grey centres.',
        'what_to_avoid': 'Do not top-dress nitrogen now.',
        'ladder': [
          {'tier': 'cultural', 'action': 'Drain the field for 48h.'},
          {'tier': 'biological', 'action': 'Apply Pseudomonas.'},
          {
            'tier': 'chemical',
            'action': 'Tricyclazole 75 WP',
            'dosage': '0.6 g per litre',
            'phi_days': 30,
            'reentry_hours': 24,
          },
        ],
        'expert_trigger': 'If lesions cover >25% leaves, escalate.',
      };
      final advisory = AdvisoryModel.fromJson(advisoryJson);
      expect(advisory.possibleIssue, 'Early blast (confidence: high).');
      expect(advisory.ladder.length, 3);
      expect(advisory.ladder[2].tier, 'chemical');
      expect(advisory.ladder[2].dosage, '0.6 g per litre');
      expect(advisory.ladder[2].phiDays, 30);
      expect(advisory.ladder[2].reentryHours, 24);
    });

    test('Label Check models serialization', () {
      final labelJson = {
        'extracted': {
          'active_ingredient': 'carbendazim',
          'concentration': '50% WP',
          'formulation': 'wettable powder',
          'ocr_confidence': 0.82,
        },
        'verdict': {
          'code': 'WRONG_CLASS',
          'message': 'This is a fungicide. Your problem is an insect pest.',
          'matched_row_id': 'ru_14',
        },
        'spoken_summary': 'हे बुरशीनाशक आहे.',
      };
      final labelCheck = LabelCheckResponse.fromJson(labelJson);
      expect(labelCheck.isReadable, isTrue);
      expect(labelCheck.extracted.activeIngredient, 'carbendazim');
      expect(labelCheck.verdict?.code, 'WRONG_CLASS');
      expect(labelCheck.verdict?.message,
          'This is a fungicide. Your problem is an insect pest.');
    });

    test('Alert models serialization', () {
      final alertJson = {
        'id': 'al_1',
        'trigger_type': 'weather',
        'target': 'blast',
        'risk_level': 'high',
        'reason': 'Humidity above 90% for 4 consecutive nights.',
        'inspection_tasks': [
          'Check the upper leaves on 10 plants.',
          'Photograph any spot with a grey centre.',
        ],
        'issued_at': '2026-08-29T04:00:00Z',
        'outcome': null,
      };
      final alert = AlertModel.fromJson(alertJson);
      expect(alert.id, 'al_1');
      expect(alert.riskLevel, 'high');
      expect(alert.inspectionTasks.length, 2);
      expect(alert.inspectionTasks[0], 'Check the upper leaves on 10 plants.');
    });

    test('Follow-up models serialization', () {
      final followupJson = {
        'id': 'fu_1',
        'problem_id': 'p_7',
        'due_at': '2026-08-30T10:00:00Z',
        'response': 'improved',
      };
      final followup = FollowUpModel.fromJson(followupJson);
      expect(followup.id, 'fu_1');
      expect(followup.response, 'improved');

      final resultJson = {
        'problem_id': 'p_7',
        'severity_change': {'from': 'early', 'to': 'moderate'},
        'health': {
          'sentence': 'Problem worsening despite treatment.',
          'trend': 'worsening'
        },
        'escalated': true,
        'case_id': 'c_5',
      };
      final result = FollowUpResultModel.fromJson(resultJson);
      expect(result.problemId, 'p_7');
      expect(result.severityChange?.from, 'early');
      expect(result.severityChange?.to, 'moderate');
      expect(result.escalated, isTrue);
      expect(result.caseId, 'c_5');
    });

    test('Problem and Timeline models serialization', () {
      final problemJson = {
        'id': 'p_101',
        'farm_id': 'f_1',
        'problem_type': 'disease',
        'label': 'blast',
        'severity': 'moderate',
        'status': 'open',
        'opened_at': '2026-08-30T10:00:00Z',
      };
      final problem = ProblemModel.fromJson(problemJson);
      expect(problem.id, 'p_101');
      expect(problem.label, 'blast');
      expect(problem.severity, 'moderate');

      final timelineJson = {
        'id': 'ev_1',
        'type': 'diagnosis',
        'title': 'Blast Diagnosed',
        'description': 'Early leaf lesions found.',
        'timestamp': '2026-08-30T10:05:00Z',
      };
      final event = TimelineEventModel.fromJson(timelineJson);
      expect(event.id, 'ev_1');
      expect(event.type, 'diagnosis');
      expect(event.title, 'Blast Diagnosed');
    });

    test('Referral and Asset models serialization', () {
      final referralJson = {
        'kind': 'kvk',
        'name': 'KVK Nashik',
        'phone': '+912532456789',
        'distance_km': 12.4,
        'accepts_samples': true,
      };
      final referral = ReferralModel.fromJson(referralJson);
      expect(referral.kind, 'kvk');
      expect(referral.name, 'KVK Nashik');
      expect(referral.distanceKm, 12.4);
      expect(referral.acceptsSamples, isTrue);

      final presignedJson = {
        'asset_id': 'a_9',
        'upload_url': 'https://storage.bhoomi.internal/assets/a_9',
        'method': 'PUT',
        'expires_in': 600,
      };
      final presigned = PresignedAssetModel.fromJson(presignedJson);
      expect(presigned.assetId, 'a_9');
      expect(presigned.uploadUrl,
          'https://storage.bhoomi.internal/assets/a_9');
      expect(presigned.method, 'PUT');
    });

    test('Voice and System Health models serialization', () {
      final voiceJson = {
        'text': 'माझं भात तिळरी अवस्थेत आहे',
        'confidence': 0.89,
        'lang': 'mr-IN',
        'parsed_intent': {'field': 'growth_stage', 'value': 'tillering'},
        'needs_confirmation': true,
      };
      final voice = VoiceTranscribeResult.fromJson(voiceJson);
      expect(voice.text, 'माझं भात तिळरी अवस्थेत आहे');
      expect(voice.confidence, 0.89);
      expect(voice.parsedIntent?.field, 'growth_stage');
      expect(voice.parsedIntent?.value, 'tillering');
      expect(voice.needsConfirmation, isTrue);

      final healthJson = {
        'status': 'ok',
        'version': '2.0.0',
        'vision_model': 'real',
        'is_stub': false,
      };
      final health = SystemHealthModel.fromJson(healthJson);
      expect(health.status, 'ok');
      expect(health.visionModel, 'real');
      expect(health.isStub, isFalse);
    });
  });
}
