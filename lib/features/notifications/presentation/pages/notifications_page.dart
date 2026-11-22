import 'package:edubridge_mobile_application/config/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../domain/entities/app_notification.dart';
import '../providers/notification_providers.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    return auth.when(
      loading: () => _page(
        title: 'Notifications',
        fallbackPath: '/',
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => _page(
        title: 'Notifications',
        fallbackPath: '/',
        body: const _NotificationMessage(
          message: 'Unable to verify your account. Please try again.',
        ),
      ),
      data: (user) {
        if (user == null || user.requiresAccountSetup) {
          return _page(
            title: 'Notifications',
            fallbackPath: '/',
            body: const _NotificationMessage(
              message: 'Sign in with a complete account to view notifications.',
            ),
          );
        }

        final fallbackPath = switch (user.role) {
          UserRole.company => '/company/dashboard',
          UserRole.talent => '/talent/dashboard',
          UserRole.admin => '/admin/dashboard',
        };
        final notificationsAsync = ref.watch(
          userNotificationsProvider(user.id),
        );
        return _page(
          title: 'Notifications',
          fallbackPath: fallbackPath,
          body: notificationsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => _NotificationMessage(
              message: 'Could not load notifications: $error',
              onRetry: () =>
                  ref.invalidate(userNotificationsProvider(user.id)),
            ),
            data: (notifications) => _NotificationList(
              userId: user.id,
              notifications: notifications,
            ),
          ),
        );
      },
    );
  }

  Scaffold _page({
    required String title,
    required String fallbackPath,
    required Widget body,
  }) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(fallbackPath: fallbackPath),
        title: Text(title),
      ),
      body: body,
    );
  }
}

class _NotificationList extends ConsumerStatefulWidget {
  const _NotificationList({
    required this.userId,
    required this.notifications,
  });

  final String userId;
  final List<AppNotification> notifications;

  @override
  ConsumerState<_NotificationList> createState() => _NotificationListState();
}

class _NotificationListState extends ConsumerState<_NotificationList> {
  bool _isMarkingAllRead = false;

  @override
  Widget build(BuildContext context) {
    final unreadCount = widget.notifications
        .where((notification) => !notification.isRead)
        .length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                unreadCount == 0 ? 'All caught up' : '$unreadCount unread',
                style: const TextStyle(
                  color: Color(0xFF9AA7BA),
                  fontSize: AppTypography.body,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (unreadCount > 0)
              TextButton(
                onPressed: _isMarkingAllRead ? null : _markAllRead,
                child: Text(_isMarkingAllRead ? 'Saving...' : 'Mark all read'),
              ),
          ],
        ),
        if (widget.notifications.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: _NotificationMessage(
              message: 'You do not have any notifications yet.',
            ),
          )
        else
          ...widget.notifications.map(
            (notification) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _NotificationTile(
                notification: notification,
                onTap: notification.isRead
                    ? null
                    : () => _markRead(notification),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _markRead(AppNotification notification) async {
    try {
      await ref.read(markNotificationReadProvider)(notification.id);
    } catch (error) {
      if (!mounted) return;
      _showMessage('Could not mark notification as read: $error');
    }
  }

  Future<void> _markAllRead() async {
    setState(() => _isMarkingAllRead = true);
    try {
      await ref.read(markAllNotificationsReadProvider)(
        userId: widget.userId,
        notifications: widget.notifications,
      );
    } catch (error) {
      if (!mounted) return;
      _showMessage('Could not mark notifications as read: $error');
    } finally {
      if (mounted) setState(() => _isMarkingAllRead = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, this.onTap});

  final AppNotification notification;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: notification.isRead
          ? const Color(0xFF202434)
          : const Color(0xFF2B215A),
      borderRadius: BorderRadius.circular(14),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          notification.type == 'shortlisted'
              ? Icons.star_outline_rounded
              : Icons.notifications_none_rounded,
          color: notification.isRead
              ? const Color(0xFF9AA7BA)
              : const Color(0xFFC09AFF),
        ),
        title: Text(
          notification.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: AppTypography.body,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            notification.message,
            style: const TextStyle(
              color: Color(0xFFB4C0D1),
              fontSize: AppTypography.body,
              height: 1.4,
            ),
          ),
        ),
        trailing: notification.isRead
            ? null
            : const Icon(
                Icons.circle,
                size: 9,
                color: Color(0xFFF59E0B),
              ),
      ),
    );
  }
}

class _NotificationMessage extends StatelessWidget {
  const _NotificationMessage({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              TextButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}
