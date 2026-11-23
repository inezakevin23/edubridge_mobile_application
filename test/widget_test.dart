import 'package:edubridge_mobile_application/config/theme/app_theme.dart';
import 'package:edubridge_mobile_application/features/auth/presentation/pages/landing_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('landing page renders with the EduBridge dark theme', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const LandingPage()),
    );

    expect(find.text('EduBridge'), findsOneWidget);
    expect(find.text('Create an account'), findsOneWidget);
    expect(find.text('I already have an account'), findsOneWidget);
    expect(AppTheme.dark.brightness, Brightness.dark);
    expect(AppTheme.dark.scaffoldBackgroundColor, AppTheme.pageBackground);
    expect(AppTheme.dark.colorScheme.primary, AppTheme.primary);
  });
}
