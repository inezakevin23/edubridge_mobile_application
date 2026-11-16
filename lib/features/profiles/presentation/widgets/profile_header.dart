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
    return Column(
      children: [
        CircleAvatar(
          radius: 43,
          backgroundColor: colors.primaryContainer,
          backgroundImage: photoUrl.trim().isEmpty
              ? null
              : NetworkImage(photoUrl),
          child: photoUrl.trim().isEmpty
              ? Icon(
                  isCompany ? Icons.business : Icons.person,
                  size: 42,
                  color: colors.onPrimaryContainer,
                )
              : null,
        ),
        const SizedBox(height: 12),
        Text(
          name.isEmpty ? (isCompany ? 'Company name' : 'Your name') : name,
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
