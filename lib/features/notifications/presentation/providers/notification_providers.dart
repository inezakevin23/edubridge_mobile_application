import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../submissions/domain/entities/submission.dart';
import '../../data/datasources/firestore_notification_data_source.dart';
import '../../domain/entities/app_notification.dart';

typedef NotifyShortlistedSubmissions =
    Future<int> Function({
      required String companyId,
      required List<Submission> submissions,
    });

typedef MarkNotificationRead = Future<void> Function(String notificationId);

typedef MarkAllNotificationsRead =
    Future<void> Function({
      required String userId,
      required List<AppNotification> notifications,
    });

final firestoreNotificationDataSourceProvider =
    Provider<FirestoreNotificationDataSource>((ref) {
      return FirestoreNotificationDataSource(ref.watch(firestoreProvider));
    });

final userNotificationsProvider =
    StreamProvider.family<List<AppNotification>, String>((ref, userId) {
      return ref
          .watch(firestoreNotificationDataSourceProvider)
          .watchForUser(userId);
    });

final unreadNotificationCountProvider = Provider.family<int, String>((
  ref,
  userId,
) {
  final notifications = ref.watch(userNotificationsProvider(userId));
  return notifications.maybeWhen(
    data: (items) => items.where((notification) => !notification.isRead).length,
    orElse: () => 0,
  );
});

final notifyShortlistedSubmissionsProvider =
    Provider<NotifyShortlistedSubmissions>((ref) {
      final dataSource = ref.watch(firestoreNotificationDataSourceProvider);
      return ({required companyId, required submissions}) =>
          dataSource.notifyShortlisted(
            companyId: companyId,
            submissions: submissions,
          );
    });

final markNotificationReadProvider = Provider<MarkNotificationRead>((ref) {
  final dataSource = ref.watch(firestoreNotificationDataSourceProvider);
  return dataSource.markAsRead;
});

final markAllNotificationsReadProvider =
    Provider<MarkAllNotificationsRead>((ref) {
      final dataSource = ref.watch(firestoreNotificationDataSourceProvider);
      return ({
        required userId,
        required notifications,
      }) => dataSource.markAllAsRead(
        userId: userId,
        notifications: notifications,
      );
    });
