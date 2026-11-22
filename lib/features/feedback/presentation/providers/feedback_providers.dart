import 'package:edubridge_mobile_application/features/auth/presentation/providers/auth_providers.dart';
import 'package:edubridge_mobile_application/features/feedback/data/datasources/firestore_feedback_data_source.dart';
import 'package:edubridge_mobile_application/features/feedback/data/repositories/feedback_repository_impl.dart';
import 'package:edubridge_mobile_application/features/feedback/domain/entities/submission_feedback.dart';
import 'package:edubridge_mobile_application/features/feedback/domain/repositories/feedback_repository.dart';
import 'package:edubridge_mobile_application/features/feedback/domain/usecases/get_submission_feedback.dart';
import 'package:edubridge_mobile_application/features/feedback/domain/usecases/save_submission_feedback.dart';
import 'package:edubridge_mobile_application/features/feedback/domain/usecases/watch_submission_feedback.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firestoreFeedbackDataSourceProvider =
    Provider<FirestoreFeedbackDataSource>((ref) {
      return FirestoreFeedbackDataSource(ref.watch(firestoreProvider));
    });

final feedbackRepositoryProvider = Provider<FeedbackRepository>((ref) {
  return FeedbackRepositoryImpl(ref.watch(firestoreFeedbackDataSourceProvider));
});

final getSubmissionFeedbackUseCaseProvider = Provider<GetSubmissionFeedback>((
  ref,
) {
  return GetSubmissionFeedback(ref.watch(feedbackRepositoryProvider));
});

final watchSubmissionFeedbackUseCaseProvider =
    Provider<WatchSubmissionFeedback>((ref) {
      return WatchSubmissionFeedback(ref.watch(feedbackRepositoryProvider));
    });

final saveSubmissionFeedbackUseCaseProvider = Provider<SaveSubmissionFeedback>((
  ref,
) {
  return SaveSubmissionFeedback(ref.watch(feedbackRepositoryProvider));
});

final submissionFeedbackProvider =
    StreamProvider.family<SubmissionFeedback?, String>((ref, submissionId) {
      return ref
          .watch(watchSubmissionFeedbackUseCaseProvider)
          .call(submissionId);
    });

final saveSubmissionFeedbackProvider = Provider<SaveSubmissionFeedback>((ref) {
  return ref.watch(saveSubmissionFeedbackUseCaseProvider);
});
