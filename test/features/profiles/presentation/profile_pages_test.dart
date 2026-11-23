import 'package:edubridge_mobile_application/config/theme/app_theme.dart';
import 'package:edubridge_mobile_application/features/auth/domain/entities/auth_user.dart';
import 'package:edubridge_mobile_application/features/auth/presentation/providers/auth_providers.dart';
import 'package:edubridge_mobile_application/features/profiles/domain/entities/user_profile.dart';
import 'package:edubridge_mobile_application/features/profiles/presentation/pages/company_profile_page.dart';
import 'package:edubridge_mobile_application/features/profiles/presentation/pages/talent_profile_page.dart';
import 'package:edubridge_mobile_application/features/profiles/presentation/providers/profile_provider.dart';
import 'package:edubridge_mobile_application/features/notifications/presentation/providers/notification_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('talent profile presents registration details and editing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final profile = UserProfile(
      userId: 'talent-1',
      role: 'talent',
      displayName: 'Jane Awino',
      bio: 'Data scientist in training.',
      scorePoints: 87,
      registrationDetails: {
        'phone': '0700000000',
        'city': 'Nairobi',
        'country': 'Kenya',
        'currentStatus': 'Student',
        'fieldOfStudy': 'Data Science',
        'institution': 'University of Nairobi',
        'graduationYear': '2026',
        'yearsOfExperience': '0',
        'skills': ['Python', 'Pandas', 'NumPy'],
      },
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(
              const AuthUser(
                id: 'talent-1',
                email: 'jane@example.com',
                role: UserRole.talent,
              ),
            ),
          ),
          profileStreamProvider('talent-1')
              .overrideWith((ref) => Stream.value(profile)),
          unreadNotificationCountProvider.overrideWith((ref, userId) => 0),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const TalentProfilePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Jane Awino'), findsOneWidget);
    expect(find.text('Student · Data Science'), findsOneWidget);
    expect(find.text('University of Nairobi'), findsOneWidget);
    expect(find.text('Score points'), findsOneWidget);
    expect(find.text('Python'), findsOneWidget);
    expect(find.text('Feedback'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Edit profile'));
    await tester.pumpAndSettle();
    expect(find.text('Basic information'), findsOneWidget);
    expect(find.byTooltip('Cancel editing'), findsOneWidget);
  });

  testWidgets('company profile uses the shared profile layout', (tester) async {
    tester.view.physicalSize = const Size(285, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final profile = UserProfile(
      userId: 'company-1',
      role: 'company',
      displayName: 'EduBridge Labs',
      companyDescription: 'Building opportunities for emerging talent.',
      industry: 'Technology',
      website: 'https://edubridge.example',
      registrationDetails: {
        'phone': '0700000000',
        'city': 'Nairobi',
        'country': 'Kenya',
        'businessType': 'Startup',
        'representativeName': 'Jane Awino',
        'representativeTitle': 'Talent Lead',
      },
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(
              const AuthUser(
                id: 'company-1',
                email: 'company@example.com',
                role: UserRole.company,
              ),
            ),
          ),
          profileStreamProvider('company-1')
              .overrideWith((ref) => Stream.value(profile)),
          unreadNotificationCountProvider.overrideWith((ref, userId) => 0),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const CompanyProfilePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('EduBridge Labs'), findsOneWidget);
    expect(find.text('Company account'), findsOneWidget);
    expect(find.text('Company Overview'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Business Type'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('EduBridge Labs'), findsNWidgets(2));
    expect(find.text('Business Type'), findsOneWidget);
    expect(find.text('Startup'), findsOneWidget);
    expect(find.text('Post Challenge'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Authorized Representative'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Organization Details'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('CORPORATE EMAIL'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('CORPORATE EMAIL'), findsOneWidget);
    expect(find.text('Jane Awino'), findsOneWidget);
    expect(find.text('Talent Lead'), findsOneWidget);
    expect(find.text('Submissions'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
