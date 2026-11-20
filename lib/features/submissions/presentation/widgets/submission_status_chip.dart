import 'package:flutter/material.dart';

import '../../domain/entities/submission.dart';

class SubmissionStatusChip extends StatelessWidget {
  const SubmissionStatusChip({required this.status, super.key});

  final SubmissionStatus status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final Color background;
    final Color foreground;

    switch (status) {
      case SubmissionStatus.submitted:
        background = colorScheme.tertiaryContainer;
        foreground = colorScheme.onTertiaryContainer;
        break;
      case SubmissionStatus.underReview:
        background = colorScheme.secondaryContainer;
        foreground = colorScheme.onSecondaryContainer;
        break;
      case SubmissionStatus.reviewed:
        background = colorScheme.primaryContainer;
        foreground = colorScheme.onPrimaryContainer;
        break;
    }

    return Chip(
      visualDensity: VisualDensity.compact,
      label: Text(status.label),
      backgroundColor: background,
      labelStyle: TextStyle(
        color: foreground,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide.none,
    );
  }
}
