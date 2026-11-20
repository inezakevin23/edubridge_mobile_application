import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edubridge_mobile_application/features/feedback/presentation/widgets/feedback_rating_input.dart';

void main() {
  testWidgets('shows the current feedback rating', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FeedbackRatingInput(
            rating: 4,
            onChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Overall rating: 4 / 5'), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
  });

  testWidgets('disables rating changes in read-only mode', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FeedbackRatingInput(
            rating: 5,
            onChanged: (_) {},
            enabled: false,
          ),
        ),
      ),
    );

    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.onChanged, isNull);
  });
}
