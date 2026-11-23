import 'package:flutter/material.dart';

class FeedbackRatingInput extends StatelessWidget {
  const FeedbackRatingInput({
    required this.rating,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  final int rating;
  final ValueChanged<int> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overall rating: $rating / 5',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Slider(
          value: rating.toDouble(),
          min: 1,
          max: 5,
          divisions: 4,
          label: '$rating / 5',
          onChanged: enabled ? (value) => onChanged(value.round()) : null,
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text('Needs improvement'), Text('Excellent')],
        ),
      ],
    );
  }
}
