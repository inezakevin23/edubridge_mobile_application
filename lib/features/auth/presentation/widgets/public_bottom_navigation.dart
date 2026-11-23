import 'package:edubridge_mobile_application/config/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';


class PublicBottomNavigation extends StatelessWidget {
  const PublicBottomNavigation({required this.selectedIndex, super.key});

  final int selectedIndex;

  static const _items = [
    (
      label: 'Student',
      icon: Icons.person_outline_rounded,
      route: '/student-registration',
    ),
    (
      label: 'Company',
      icon: Icons.business_center_outlined,
      route: '/company-registration',
    ),
    (
      label: 'Challenges',
      icon: Icons.emoji_events_outlined,
      route: '/challenges',
    ),
    (label: 'Sign In', icon: Icons.login_rounded, route: '/login'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF171C28),
        border: Border(top: BorderSide(color: Color(0xFF252B38))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              for (var index = 0; index < _items.length; index++)
                Expanded(
                  child: _NavigationItem(
                    item: _items[index],
                    selected: selectedIndex == index,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({required this.item, required this.selected});

  final ({String label, IconData icon, String route}) item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.primary : const Color(0xFF747C8C);
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: InkWell(
        onTap: () => context.go(item.route),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: selected
                    ? AppTheme.primary.withValues(alpha: 0.18)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, size: 19, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: AppTypography.caption,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
