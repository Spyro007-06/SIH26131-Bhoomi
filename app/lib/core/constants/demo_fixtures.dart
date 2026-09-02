import '../../models/auth_models.dart';
import '../../models/farm_models.dart';
import '../../models/alert_models.dart';
import '../../models/followup_models.dart';
import '../../models/timeline_models.dart';
import '../../models/referral_models.dart';
import '../config/demo_config.dart';

/// Pre-populated realistic demonstration fixtures for SIH presentations.
/// Ensures the Bhoomi Farmer app displays a rich, credible farmer profile
/// and field state during live evaluations even in offline environments.
abstract final class DemoFixtures {
  static const UserModel demoUser = UserModel(
    id: DemoConfig.demoFarmerId,
    phone: DemoConfig.demoPhone,
    name: DemoConfig.demoFarmerName,
    role: DemoConfig.demoRole,
  );

  static const FarmModel demoFarm = FarmModel(
    id: DemoConfig.demoFarmId,
    crop: DemoConfig.demoCrop,
    variety: DemoConfig.demoVariety,
    growthStage: DemoConfig.demoGrowthStage,
    region: 'Nashik',
    location: GeoPoint(
      lat: DemoConfig.demoLatitude,
      lng: DemoConfig.demoLongitude,
    ),
  );

  static const FarmSummaryModel demoFarmSummary = FarmSummaryModel(
    farm: demoFarm,
    health: HealthModel(
      sentence: 'Field health is stable. Active monitoring for Kharif Paddy.',
      trend: 'stable',
    ),
    activeProblemsCount: 1,
    pendingFollowUpsCount: 1,
    activeAlertsCount: 1,
  );

  static const List<AlertModel> demoAlerts = [
    AlertModel(
      id: 'alt_demo_01',
      triggerType: 'weather',
      target: 'blast',
      riskLevel: 'moderate',
      reason: 'paddy_blast_favourability',
      inspectionTasks: [
        'Inspect upper leaves for brown spindle-shaped spots with grey centres.',
        'Check water drainage and avoid excess nitrogen top-dressing.',
      ],
      issuedAt: '2026-09-01T08:00:00Z',
      spokenSummary: 'भातावरील करपा रोगासाठी अनुकूल हवामान नोंदवले गेले आहे.',
      farmId: DemoConfig.demoFarmId,
    ),
  ];

  static const List<FollowUpModel> demoPendingFollowUps = [
    FollowUpModel(
      id: 'fu_demo_01',
      problemId: 'p_demo_01',
      dueAt: '2026-09-02T10:00:00Z',
      target: 'paddy_blast',
      question: 'Have the spindle lesions on upper leaves reduced following cultural aeration?',
      farmId: DemoConfig.demoFarmId,
    ),
  ];

  static const List<TimelineEventModel> demoTimeline = [
    TimelineEventModel(
      id: 'tl_demo_01',
      type: 'advisory',
      title: 'IPM Advisory Issued (एकात्मिक कीड व्यवस्थापन सल्ला)',
      description: 'Cultural aeration recommended. Chemical insecticide vetoed — fungal pathogen detected.',
      timestamp: '2026-08-30T10:30:00Z',
    ),
    TimelineEventModel(
      id: 'tl_demo_02',
      type: 'diagnosis',
      title: 'Crop Diagnosis Completed (पीक रोग निदान)',
      description: 'High confidence detection of Paddy Blast (करपा) at 94% certainty.',
      timestamp: '2026-08-30T10:15:00Z',
    ),
    TimelineEventModel(
      id: 'tl_demo_03',
      type: 'alert',
      title: 'Regional Weather Advisory (हवामान सल्ला)',
      description: 'Consecutive high-humidity night alert registered for Nashik cluster.',
      timestamp: '2026-08-28T06:00:00Z',
    ),
  ];

  static final List<ReferralModel> demoReferrals = [
    const ReferralModel(
      kind: 'kvk',
      name: 'KVK Nashik (कृषी विज्ञान केंद्र, नाशिक)',
      phone: '0253-2231265',
      address: 'KVK Yashwantrao Chavan Open University Campus, Dindori Road, Nashik - 422222',
      distanceKm: 2.1,
      acceptsSamples: true,
    ),
    const ReferralModel(
      kind: 'helpline',
      name: 'Kisan Call Centre (किसान कॉल सेंटर - भारत सरकार)',
      phone: '1800-180-1551',
      address: 'National Helpline (Toll-Free 24x7 in Marathi, Hindi, English)',
      distanceKm: 0.0,
      acceptsSamples: false,
    ),
    const ReferralModel(
      kind: 'lab',
      name: 'District Plant Health Clinic (जिल्हा वनस्पती आरोग्य क्लिनिक)',
      phone: '0253-2571234',
      address: 'Department of Agriculture Complex, CBS Circle, Nashik',
      distanceKm: 5.4,
      acceptsSamples: true,
    ),
  ];
}
