import 'package:edubridge_mobile_application/features/dashboards/presentation/widgets/dashboard_header.dart';
import 'package:edubridge_mobile_application/features/notifications/presentation/providers/notification_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('unread indicator appears only when there are unread items', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          unreadNotificationCountProvider.overrideWith(
            (ref, userId) => userId == 'unread-user' ? 1 : 0,
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            appBar: DashboardHeader(notificationUserId: 'unread-user'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('unread-notification-indicator')),
      findsOneWidget,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          unreadNotificationCountProvider.overrideWith(
            (ref, userId) => 0,
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            appBar: DashboardHeader(notificationUserId: 'no-unread-user'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('unread-notification-indicator')),
      findsNothing,
    );
  });
}
