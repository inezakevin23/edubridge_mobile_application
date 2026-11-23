import 'package:edubridge_mobile_application/config/theme/app_theme.dart';
import 'package:edubridge_mobile_application/features/auth/presentation/pages/landing_page.dart';
import 'package:edubridge_mobile_application/features/auth/presentation/widgets/public_bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:edubridge_mobile_application/features/challenges/domain/entities/challenge.dart';
import 'package:edubridge_mobile_application/features/challenges/presentation/providers/challenge_provider.dart';

void main() {
  testWidgets('landing page matches the EduBridge Africa homepage', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          openChallengesProvider.overrideWith(
            (ref) => Stream.value([
              Challenge(
                id: 'public-brief',
                companyId: 'company-1',
                title: 'Community Garden Plan',
                description: 'Plan an accessible community garden.',
                category: 'Technology',
                requiredSkills: const ['Design'],
                requirements: const ['Create a project plan'],
                deadline: DateTime.now().add(const Duration(days: 14)),
                status: ChallengeStatus.open,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            ]),
          ),
        ],
        child: MaterialApp(theme: AppTheme.dark, home: const LandingPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('EduBridge'), findsOneWidget);
    expect(find.byType(PublicBottomNavigation), findsOneWidget);
    expect(find.text('Get Started'), findsNothing);
    expect(
      find.text('Bridging the gap between education and employment in Africa'),
      findsOneWidget,
    );
    expect(find.text('Career Opportunities'), findsOneWidget);
    expect(AppTheme.dark.brightness, Brightness.dark);
    expect(AppTheme.dark.scaffoldBackgroundColor, AppTheme.pageBackground);
    expect(AppTheme.dark.colorScheme.primary, AppTheme.primary);

    await tester.scrollUntilVisible(
      find.text('Bridging Education and Employment'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Why EduBridge'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Challenges interns can solve now'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Latest Opportunities'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Community Garden Plan'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('View Challenge'), findsOneWidget);
  });
}
