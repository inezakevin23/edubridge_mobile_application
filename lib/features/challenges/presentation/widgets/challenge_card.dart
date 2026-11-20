import 'package:flutter/material.dart';

import '../../domain/entities/challenge.dart';

class ChallengeCard extends StatelessWidget {
  const ChallengeCard({
    required this.challenge,
    this.onTap,
    this.trailing,
    super.key,
  });

  final Challenge challenge;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = MaterialLocalizations.of(context)
        .formatMediumDate(challenge.deadline.toLocal());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      challenge.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 8),
                    trailing!,
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text(
                challenge.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(
                    icon: Icons.category_outlined,
                    label: challenge.category,
                  ),
                  _InfoChip(
                    icon: Icons.calendar_month_outlined,
                    label: 'Deadline: $date',
                  ),
                  _InfoChip(
                    icon: challenge.isOpen
                        ? Icons.lock_open
                        : Icons.lock_outline,
                    label: challenge.status.name.toUpperCase(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      visualDensity: VisualDensity.compact,
      avatar: Icon(icon, size: 16),
      label: Text(label, style: Theme.of(context).textTheme.labelSmall),
      padding: EdgeInsets.zero,
    );
  }
}
