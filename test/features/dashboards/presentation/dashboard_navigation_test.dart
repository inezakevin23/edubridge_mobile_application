import 'package:edubridge_mobile_application/config/theme/app_theme.dart';
import 'package:edubridge_mobile_application/features/auth/domain/repositories/auth_repository.dart';
import 'package:edubridge_mobile_application/features/auth/presentation/providers/auth_providers.dart';
import 'package:edubridge_mobile_application/features/dashboards/presentation/widgets/dashboard_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('logout navigation signs out and routes to sign-in', (
    tester,
  ) async {
    final authRepository = _FakeAuthRepository();
    final router = GoRouter(
      initialLocation: '/dashboard',
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => Scaffold(
            body: const Text('Dashboard screen'),
            bottomNavigationBar: DashboardNavigation(
              currentIndex: 0,
              onIndexChanged: (_) {},
            ),
          ),
        ),
        GoRoute(
          path: '/sign-in',
          builder: (context, state) =>
              const Scaffold(body: Text('Sign-in screen')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWithValue(
            AuthController(authRepository),
          ),
        ],
        child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
      ),
    );

    expect(find.text('Logout'), findsOneWidget);
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();

    expect(authRepository.didSignOut, isTrue);
    expect(find.text('Sign-in screen'), findsOneWidget);
  });
}

class _FakeAuthRepository implements AuthRepository {
  bool didSignOut = false;

  @override
  Future<void> signOut() async {
    didSignOut = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
