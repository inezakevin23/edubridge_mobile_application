import 'package:edubridge_mobile_application/config/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_providers.dart';

class DashboardNavigation extends ConsumerStatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;
  final bool isCompany;

  const DashboardNavigation({
    super.key,
    required this.currentIndex,
    required this.onIndexChanged,
    this.isCompany = false,
  });

  @override
  ConsumerState<DashboardNavigation> createState() =>
      _DashboardNavigationState();
}

class _DashboardNavigationState extends ConsumerState<DashboardNavigation> {
  bool _isSigningOut = false;

  Future<void> _signOut() async {
    if (_isSigningOut) return;
    setState(() => _isSigningOut = true);
    try {
      await ref.read(authControllerProvider).signOut();
      if (mounted) context.go('/sign-in');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not log out: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF171923),
        border: const Border(top: BorderSide(color: Color(0xFF252B38))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _buildNavItem(
              index: 0,
              icon: Icons.dashboard_outlined,
              activeIcon: Icons.dashboard_rounded,
              label: 'Dashboard',
              theme: theme,
            ),
            _buildNavItem(
              index: 1,
              icon: widget.isCompany
                  ? Icons.business_center_outlined
                  : Icons.military_tech_outlined,
              activeIcon: widget.isCompany
                  ? Icons.business_center_rounded
                  : Icons.military_tech,
              label: widget.isCompany ? 'Manage' : 'Challenges',
              theme: theme,
            ),
            _buildNavItem(
              index: 2,
              icon: widget.isCompany
                  ? Icons.inbox_outlined
                  : Icons.chat_bubble_outline_rounded,
              activeIcon: widget.isCompany
                  ? Icons.inbox_rounded
                  : Icons.chat_bubble_rounded,
              label: widget.isCompany ? 'Submissions' : 'Feedback',
              theme: theme,
            ),
            _buildNavItem(
              index: 3,
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: 'Profile',
              theme: theme,
            ),
            _buildNavItem(
              index: 4,
              icon: Icons.logout_rounded,
              activeIcon: Icons.logout_rounded,
              label: _isSigningOut ? 'Please wait' : 'Logout',
              theme: theme,
              isLogout: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required ThemeData theme,
    bool isLogout = false,
  }) {
    final isSelected = !isLogout && widget.currentIndex == index;
    final color = isLogout
        ? const Color(0xFFE57373)
        : isSelected
        ? theme.colorScheme.primary
        : const Color(0xFF747C8C);

    final fullLabel = widget.isCompany && index == 1
        ? 'Manage challenges'
        : isLogout
        ? 'Log out'
        : label;
    return Expanded(
      child: Tooltip(
        message: fullLabel,
        child: InkWell(
          onTap: isLogout
              ? (_isSigningOut ? null : _signOut)
              : () {
                  if (widget.isCompany && index == 1) {
                    context.go('/company/challenges/create');
                  } else {
                    widget.onIndexChanged(index);
                  }
                },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary.withValues(alpha: 0.18)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: _isSigningOut && isLogout
                      ? Padding(
                          padding: const EdgeInsets.all(7),
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: color,
                          ),
                        )
                      : Icon(
                          isSelected ? activeIcon : icon,
                          color: color,
                          size: 18,
                        ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: AppTypography.micro,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
