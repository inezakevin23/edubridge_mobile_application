import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../submissions/domain/entities/submission.dart';
import '../../domain/entities/app_notification.dart';

class FirestoreNotificationDataSource {
  const FirestoreNotificationDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection('notifications');

  Stream<List<AppNotification>> watchForUser(String userId) {
    return _notifications
        .where('recipientId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final notifications = snapshot.docs.map(_fromDocument).toList();
          notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return notifications;
        });
  }

  Future<int> notifyShortlisted({
    required String companyId,
    required List<Submission> submissions,
  }) async {
    final shortlisted = submissions
        .where((submission) => submission.isShortlisted)
        .toList(growable: false);
    if (shortlisted.isEmpty) return 0;
    if (shortlisted.any((submission) => submission.companyId != companyId)) {
      throw ArgumentError(
        'A company can only notify students from its own submissions.',
      );
    }
    if (shortlisted.length > 500) {
      throw StateError(
        'Notify no more than 500 shortlisted submissions at a time.',
      );
    }

    var createdCount = 0;
    for (final submission in shortlisted) {
      final reference = _notifications.doc('shortlist_${submission.id}');
      final created = await _firestore.runTransaction((transaction) async {
        if ((await transaction.get(reference)).exists) return false;
        transaction.set(reference, {
          'recipientId': submission.talentId,
          'senderId': companyId,
          'title': 'You were shortlisted',
          'message': 'Your submission has been shortlisted.',
          'type': 'shortlisted',
          'relatedSubmissionId': submission.id,
          'isRead': false,
          'createdAt': Timestamp.fromDate(DateTime.now().toUtc()),
        });
        return true;
      });
      if (created) createdCount++;
    }
    return createdCount;
  }

  Future<void> markAsRead(String notificationId) {
    return _notifications.doc(notificationId).update({'isRead': true});
  }

  Future<void> markAllAsRead({
    required String userId,
    required List<AppNotification> notifications,
  }) async {
    final unread = notifications
        .where((notification) => !notification.isRead)
        .toList(growable: false);
    if (unread.any((notification) => notification.recipientId != userId)) {
      throw ArgumentError("Cannot update another user's notifications.");
    }
    for (var start = 0; start < unread.length; start += 500) {
      final end = (start + 500).clamp(0, unread.length).toInt();
      final batch = _firestore.batch();
      for (final notification in unread.sublist(start, end)) {
        batch.update(_notifications.doc(notification.id), {'isRead': true});
      }
      await batch.commit();
    }
  }

  AppNotification _fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final createdAt = data['createdAt'];
    if (createdAt is! Timestamp) {
      throw FormatException(
        'Notification ${document.id} has an invalid createdAt field.',
      );
    }
    if (data['recipientId'] is! String ||
        data['title'] is! String ||
        data['message'] is! String ||
        data['type'] is! String ||
        data['isRead'] is! bool) {
      throw FormatException('Notification ${document.id} has invalid fields.');
    }

    return AppNotification(
      id: document.id,
      recipientId: data['recipientId'] as String,
      title: data['title'] as String,
      message: data['message'] as String,
      type: data['type'] as String,
      relatedSubmissionId: data['relatedSubmissionId'] as String?,
      isRead: data['isRead'] as bool,
      createdAt: createdAt.toDate(),
    );
  }
}
