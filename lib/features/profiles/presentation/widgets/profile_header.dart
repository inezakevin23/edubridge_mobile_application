import 'package:edubridge_mobile_application/config/theme/app_theme.dart';
import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.name,
    required this.subtitle,
    this.photoUrl = '',
    this.isCompany = false,
  });

  final String name;
  final String subtitle;
  final String photoUrl;
  final bool isCompany;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final displayName = name.isEmpty
        ? (isCompany ? 'Company name' : 'Your name')
        : name;
    final initials = displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join()
        .toUpperCase();
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: const Color(0xFF332061),
          backgroundImage: photoUrl.trim().isEmpty
              ? null
              : NetworkImage(photoUrl),
          child: photoUrl.trim().isEmpty
              ? Text(
                  initials.isEmpty ? (isCompany ? 'CO' : 'TA') : initials,
                  style: const TextStyle(
                    color: Color(0xFFC09AFF),
                    fontSize: AppTypography.body,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : null,
        ),
        const SizedBox(height: 8),
        Text(
          displayName,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontSize: AppTypography.title,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontSize: AppTypography.micro,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
