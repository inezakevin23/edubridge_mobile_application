import 'package:edubridge_mobile_application/config/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_back_button.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';

class DashboardHeader extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onNotificationTap;
  final String? notificationUserId;
  final int? scorePoints;
  final String? trailingLabel;
  final VoidCallback? onTrailingTap;
  final IconData trailingIcon;
  final bool compactScore;
  final bool showPreferences;
  final bool showBackButton;
  final String backFallbackPath;
  final VoidCallback? onEditTap;
  final bool isEditing;

  static const Color bgColor = Color(0xFF0E121A);
  static const Color primaryPurple = Color(0xFF7C3BED);

  const DashboardHeader({
    super.key,
    this.title = 'EduBridge',
    this.onNotificationTap,
    this.notificationUserId,
    this.scorePoints,
    this.trailingLabel,
    this.onTrailingTap,
    this.trailingIcon = Icons.business_center_outlined,
    this.compactScore = false,
    this.showPreferences = false,
    this.showBackButton = false,
    this.backFallbackPath = '/',
    this.onEditTap,
    this.isEditing = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = notificationUserId == null
        ? 0
        : ref.watch(unreadNotificationCountProvider(notificationUserId!));
    final compactHeader = MediaQuery.sizeOf(context).width < 360;
    final brandMark = Container(
      width: 23,
      height: 23,
      decoration: BoxDecoration(
        color: primaryPurple.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(7),
      ),
      alignment: Alignment.center,
      child: const Text(
        'EB',
        style: TextStyle(
          color: Color(0xFFC4A3FF),
          fontSize: AppTypography.micro,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
    return AppBar(
      leading: showBackButton
          ? AppBackButton(fallbackPath: backFallbackPath)
          : null,
      leadingWidth: showBackButton ? 42 : null,
      titleSpacing: showBackButton ? 4 : 16,
      backgroundColor: bgColor,
      elevation: 0,
      title: compactHeader
          ? Tooltip(message: title, child: brandMark)
          : Row(
              children: [
                brandMark,
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: AppTypography.caption,
                    ),
                  ),
                ),
              ],
            ),
      actions: [
        if (showPreferences)
          IconButton(
            tooltip: 'Preferences',
            icon: const Icon(Icons.settings_outlined, color: Colors.white70),
            onPressed: () => context.push('/preferences'),
          ),
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              tooltip: 'Notifications',
              icon: const Icon(Icons.notifications_none, color: Colors.white70),
              onPressed:
                  onNotificationTap ?? () => context.push('/notifications'),
            ),
            if (unreadCount > 0)
              Positioned(
                top: 13,
                right: 13,
                child: Container(
                  key: const ValueKey('unread-notification-indicator'),
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF59E0B),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        if (scorePoints != null || trailingLabel != null)
          Container(
            margin: const EdgeInsets.only(right: 6, top: 12, bottom: 12),
            child: _HeaderTrailing(
              icon: scorePoints != null ? Icons.emoji_events : trailingIcon,
              label: scorePoints != null
                  ? compactScore
                        ? '$scorePoints pts'
                        : '$scorePoints Score Points'
                  : trailingLabel!,
              onTap: onTrailingTap,
            ),
          ),
        if (onEditTap != null)
          IconButton(
            tooltip: isEditing ? 'Cancel editing' : 'Edit profile',
            onPressed: onEditTap,
            icon: Icon(
              isEditing ? Icons.close_rounded : Icons.edit_outlined,
              size: 18,
              color: Colors.white70,
            ),
          ),
      ],
    );
  }
}

class _HeaderTrailing extends StatelessWidget {
  const _HeaderTrailing({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Color(0xFF2A3042)),
    );
    final child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFFFFB423)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: AppTypography.micro,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    return Material(
      color: const Color(0xFF202434),
      shape: shape,
      child: onTap == null
          ? child
          : Tooltip(
              message: label,
              child: InkWell(onTap: onTap, customBorder: shape, child: child),
            ),
    );
  }
}
