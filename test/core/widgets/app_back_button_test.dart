import 'package:edubridge_mobile_application/core/widgets/app_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('back button pops to the previous screen', (tester) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => context.push('/details'),
                child: const Text('Open details'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/details',
          builder: (context, state) => Scaffold(
            appBar: AppBar(leading: const AppBackButton()),
            body: const Text('Details'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('Open details'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Go back'));
    await tester.pumpAndSettle();

    expect(find.text('Open details'), findsOneWidget);
  });

  testWidgets('back button uses its fallback for a direct route', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/details',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(body: Text('Home')),
        ),
        GoRoute(
          path: '/details',
          builder: (context, state) => Scaffold(
            appBar: AppBar(leading: const AppBackButton(fallbackPath: '/home')),
            body: const Text('Details'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Go back'));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
  });
}
