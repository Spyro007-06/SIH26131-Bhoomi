import 'package:flutter_test/flutter_test.dart';
import 'package:bhoomi/models/diagnosis_models.dart';

void main() {
  group('Diagnosis Confidence Gate Polymorphic Response Tests', () {
    test('Correctly parses outcome: "advise" payload from API_CONTRACT §6', () {
      final json = {
        'gate': {
          'outcome': 'advise',
          'confidence': 0.87,
          'threshold_applied': 0.70,
          'reason_code': 'ABOVE_GATE',
          'alternatives': [
            {'label': 'blast', 'confidence': 0.87},
            {'label': 'brown_spot', 'confidence': 0.09},
            {'label': 'bacterial_leaf_blight', 'confidence': 0.04}
          ],
          'is_stub': false,
        },
        'problem_id': 'p_7',
        'problem_type': 'disease',
        'diagnosis': {
          'label': 'blast',
          'severity': 'early',
          'confidence': 0.87,
        },
        'advisory': {
          'possible_issue': 'Early blast (confidence: high).',
          'what_to_check':
              'Diamond-shaped lesions with grey centres on upper leaves.',
          'what_to_avoid':
              'Do not top-dress nitrogen now. It accelerates spread.',
          'ladder': [
            {
              'tier': 'cultural',
              'action': 'Drain the field and let it dry for 48 hours.'
            },
            {
              'tier': 'biological',
              'action': 'Apply Pseudomonas fluorescens as a foliar spray.'
            },
            {
              'tier': 'chemical',
              'action': 'Tricyclazole 75 WP',
              'dosage': '0.6 g per litre',
              'phi_days': 30,
              'reentry_hours': 24
            }
          ],
          'expert_trigger':
              'If lesions cover more than 25% of leaves within 3 days, escalate.'
        },
        'citations': [
          {
            'doc_id': 'kb_211',
            'title': 'ICAR PoP: Rice — Blast',
            'reviewed_on': '2025-11-02'
          }
        ],
        'spoken_summary': 'करप्याची सुरुवातीची लक्षणे आहेत...',
      };

      final response = DiagnoseResponse.fromJson(json);

      // Verify gate decision
      expect(response.isAdvise, isTrue);
      expect(response.isClarify, isFalse);
      expect(response.isEscalate, isFalse);
      expect(response.gate.confidence, 0.87);
      expect(response.gate.thresholdApplied, 0.70);
      expect(response.gate.reasonCode, 'ABOVE_GATE');
      expect(response.gate.alternatives.length, 3);
      expect(response.gate.isStub, isFalse);

      // Verify Advise-specific fields
      expect(response.problemId, 'p_7');
      expect(response.problemType, 'disease');
      expect(response.diagnosis?.label, 'blast');
      expect(response.diagnosis?.severity, 'early');
      expect(response.advisory, isNotNull);
      expect(response.advisory?.whatToAvoid,
          'Do not top-dress nitrogen now. It accelerates spread.');
      expect(response.citations.length, 1);
      expect(response.citations[0].docId, 'kb_211');

      // Verify absence of other branch objects
      expect(response.clarification, isNull);
      expect(response.escalation, isNull);
    });

    test('Correctly parses outcome: "clarify" (Doubt Doctor) payload from API_CONTRACT §6', () {
      final json = {
        'gate': {
          'outcome': 'clarify',
          'confidence': 0.58,
          'threshold_applied': 0.15,
          'reason_code': 'AMBIGUOUS',
          'alternatives': [
            {'label': 'blast', 'confidence': 0.58},
            {'label': 'brown_spot', 'confidence': 0.49},
            {'label': 'bacterial_leaf_blight', 'confidence': 0.11}
          ],
          'is_stub': false,
        },
        'problem_id': 'p_7',
        'clarification': {
          'cue_id': 'cue_4',
          'question': 'Flip the leaf over. Do you see fuzzy grey growth?',
          'question_localized': 'पान उलटून पहा. करडी बुरशी दिसते का?',
          'candidates': [
            {
              'label': 'blast',
              'signature': 'Diamond-shaped spots with grey centres',
              'image_url': 'https://storage/blast.jpg'
            },
            {
              'label': 'brown_spot',
              'signature': 'Round spots with a yellow halo',
              'image_url': 'https://storage/brown_spot.jpg'
            }
          ],
          'answers': ['yes', 'no', 'unknown']
        },
        'spoken_summary': 'मला खात्री नाही. दोन शक्यता दिसतात...',
      };

      final response = DiagnoseResponse.fromJson(json);

      // Verify gate decision
      expect(response.isAdvise, isFalse);
      expect(response.isClarify, isTrue);
      expect(response.isEscalate, isFalse);
      expect(response.gate.reasonCode, 'AMBIGUOUS');
      expect(response.gate.alternatives.length, 3);

      // Verify Clarify-specific fields
      expect(response.problemId, 'p_7');
      expect(response.clarification, isNotNull);
      expect(response.clarification?.cueId, 'cue_4');
      expect(response.clarification?.question,
          'Flip the leaf over. Do you see fuzzy grey growth?');
      expect(response.clarification?.questionLocalized,
          'पान उलटून पहा. करडी बुरशी दिसते का?');
      expect(response.clarification?.candidates.length, 2);
      expect(response.clarification?.candidates[0].label, 'blast');
      expect(response.clarification?.candidates[1].label, 'brown_spot');
      expect(response.clarification?.answers, ['yes', 'no', 'unknown']);

      // Invariant 4: No advisory field on clarify outcome
      expect(response.advisory, isNull);
      expect(response.escalation, isNull);
    });

    test('Correctly parses outcome: "escalate" payload from API_CONTRACT §6', () {
      final json = {
        'gate': {
          'outcome': 'escalate',
          'confidence': 0.31,
          'threshold_applied': 0.45,
          'reason_code': 'BELOW_FLOOR',
          'alternatives': [
            {'label': 'blast', 'confidence': 0.31},
            {'label': 'brown_spot', 'confidence': 0.28},
            {'label': 'bacterial_leaf_blight', 'confidence': 0.12}
          ],
          'is_stub': false,
        },
        'problem_id': 'p_7',
        'escalation': {
          'case_id': 'c_5',
          'assigned_to': 'agronomist:kvk_nashik',
          'queue_position': 3,
          'eta_minutes': 45
        },
        'spoken_summary': 'मला खात्री नाही. तज्ञाकडे पाठवलं आहे.',
      };

      final response = DiagnoseResponse.fromJson(json);

      // Verify gate decision
      expect(response.isAdvise, isFalse);
      expect(response.isClarify, isFalse);
      expect(response.isEscalate, isTrue);
      expect(response.gate.reasonCode, 'BELOW_FLOOR');
      expect(response.gate.alternatives.length, 3);

      // Verify Escalate-specific fields
      expect(response.problemId, 'p_7');
      expect(response.escalation, isNotNull);
      expect(response.escalation?.caseId, 'c_5');
      expect(response.escalation?.assignedTo, 'agronomist:kvk_nashik');
      expect(response.escalation?.queuePosition, 3);
      expect(response.escalation?.etaMinutes, 45);

      // Invariant 4: No advisory field on escalate outcome
      expect(response.advisory, isNull);
      expect(response.clarification, isNull);
    });

    test('Doubt Doctor resolution result parses resolved and escalated branches', () {
      // Resolved branch
      final resolvedJson = {
        'resolved': true,
        'diagnosis': {
          'label': 'blast',
          'severity': 'early',
          'resolved_by': 'field_observation',
        },
        'observation_id': 'o_2',
        'advisory': {
          'possible_issue': 'Paddy Blast',
          'what_to_check': 'Diamond spots',
          'what_to_avoid': 'No nitrogen',
          'ladder': [],
        },
        'spoken_summary': 'हा करपा आहे.',
      };
      final resolvedResult = DoubtDoctorAnswerResult.fromJson(resolvedJson);
      expect(resolvedResult.resolved, isTrue);
      expect(resolvedResult.diagnosis?.resolvedBy, 'field_observation');
      expect(resolvedResult.observationId, 'o_2');
      expect(resolvedResult.advisory, isNotNull);
      expect(resolvedResult.escalation, isNull);

      // Not resolved branch
      final notResolvedJson = {
        'resolved': false,
        'reason': 'answer_did_not_discriminate',
        'observation_id': 'o_2',
        'escalation': {
          'case_id': 'c_5',
          'assigned_to': 'agronomist:kvk_nashik',
          'queue_position': 2,
          'eta_minutes': 30,
        },
        'spoken_summary': 'तज्ञाकडे पाठवतो.',
      };
      final notResolvedResult = DoubtDoctorAnswerResult.fromJson(notResolvedJson);
      expect(notResolvedResult.resolved, isFalse);
      expect(notResolvedResult.reason, 'answer_did_not_discriminate');
      expect(notResolvedResult.escalation?.caseId, 'c_5');
      expect(notResolvedResult.advisory, isNull);
    });
  });
}
