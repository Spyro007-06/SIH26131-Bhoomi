import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bhoomi/main.dart';
import 'package:bhoomi/models/referral_models.dart';
import 'package:bhoomi/repositories/referral_repository.dart';
import 'package:bhoomi/providers/repository_providers.dart';
import 'package:bhoomi/providers/farm_providers.dart';
import 'package:bhoomi/features/referrals/presentation/referrals_screen.dart';

class FakeReferralRepository extends ReferralRepository {
  bool returnEmpty = false;

  @override
  Future<ReferralsResponse> getReferrals(String farmId) async {
    if (returnEmpty) {
      return ReferralsResponse(
        kvk: null,
        districtLabs: const [],
        helpline: null,
      );
    }
    return ReferralsResponse(
      kvk: const KvkModel(
        name: 'Krishi Vigyan Kendra, Nashik',
        phone: '0253-2591234',
        address: 'Dindori Road, Nashik, Maharashtra',
        distanceKm: 14.2,
      ),
      districtLabs: const [
        DistrictLabModel(
          name: 'District Soil & Crop Health Lab',
          phone: '0253-2595678',
          address: 'Krishi Bhavan, Nashik',
        ),
      ],
      helpline: '1800-180-1551',
    );
  }
}

void main() {
  group('Referrals & Farmer Support Directory Tests (Step 5)', () {
    late FakeReferralRepository fakeReferralRepo;

    setUp(() {
      fakeReferralRepo = FakeReferralRepository();
    });

    testWidgets('Renders KVK card, helpline, district labs, and contact actions',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            referralRepositoryProvider.overrideWithValue(fakeReferralRepo),
            activeFarmIdProvider.overrideWith((ref) => ActiveFarmIdNotifier(null, 'f_nashik_01')),
          ],
          child: const BhoomiApp(homeOverride: ReferralsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify Helpline
      expect(find.text('1800-180-1551'), findsOneWidget);
      expect(find.text('शासकीय किसान कॉल सेंटर'), findsOneWidget);

      // 2. Verify KVK details
      expect(find.text('Krishi Vigyan Kendra, Nashik'), findsOneWidget);
      expect(find.text('14.2 km'), findsOneWidget);
      expect(find.textContaining('कॉल करा (0253-2591234)'), findsOneWidget);

      // 3. Verify District Labs
      expect(find.text('District Soil & Crop Health Lab'), findsOneWidget);

      // 4. Tap Call action
      await tester.tap(find.textContaining('कॉल करा (0253-2591234)'));
      await tester.pump();
      expect(find.textContaining('Calling Krishi Vigyan Kendra, Nashik'), findsOneWidget);
    });

    testWidgets('Renders empty state when no referral centers are returned',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      fakeReferralRepo.returnEmpty = true;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            referralRepositoryProvider.overrideWithValue(fakeReferralRepo),
            activeFarmIdProvider.overrideWith((ref) => ActiveFarmIdNotifier(null, 'f_nashik_01')),
          ],
          child: const BhoomiApp(homeOverride: ReferralsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('संपर्क माहिती उपलब्ध नाही'), findsOneWidget);
      expect(find.text('स्थानिक कृषी संपर्क माहिती लवकरच अद्यतनित केली जाईल.'), findsOneWidget);
    });
  });
}
