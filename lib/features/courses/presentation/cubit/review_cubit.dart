import 'package:bloc/bloc.dart';
import 'package:e_learning/core/erros/app_exceptions.dart';
import 'package:e_learning/core/erros/network_exception_handler.dart';
import 'package:e_learning/features/courses/data/repo/review_repo.dart';
import 'package:e_learning/features/courses/presentation/cubit/review_states.dart';
import 'package:e_learning/features/courses/data/model/review_model.dart';

class ReviewCubit extends Cubit<ReviewState> {
  final ReviewRepo _repo;
  final String courseId;
  final String userId;

  ReviewCubit(this._repo, {required this.courseId, required this.userId})
      : super(ReviewInitial());

  Future<void> load() async {
    emit(ReviewLoading());
    try {
      final reviews = await _repo.fetchReviews(courseId);
      final summary = ReviewSummary.fromReviews(reviews);
      final myReview = reviews.where((r) => r.userId == userId).firstOrNull;
      emit(ReviewLoaded(reviews: reviews, summary: summary, myReview: myReview));
    } catch (e) {
      final ex = e is AppException ? e : NetworkExceptionHandler.handle(e);
      emit(ReviewError(_messageForLoad(ex)));
    }
  }

  Future<bool> submitReview({
    required double rating,
    required String comment,
  }) async {
    emit(ReviewSubmitting());
    try {
      final success = await _repo.submitReview(
        userId: userId,
        courseId: courseId,
        rating: rating,
        comment: comment,
      );
      if (success) {
        await load();
        return true;
      }
      emit(ReviewError('Failed to submit your review. Please try again.'));
      return false;
    } catch (e) {
      final ex = e is AppException ? e : NetworkExceptionHandler.handle(e);
      emit(ReviewError(_messageForSubmit(ex)));
      return false;
    }
  }

  Future<void> deleteReview(String reviewId) async {
    try {
      await _repo.deleteReview(reviewId);
      await load();
    } catch (e) {
      final ex = e is AppException ? e : NetworkExceptionHandler.handle(e);
      emit(ReviewError(_messageForDelete(ex)));
    }
  }

  Future<double> getUpdatedRating() => _repo.fetchCourseRating(courseId);

  // ── Human-readable messages ─────────────────────────────────────
  String _messageForLoad(AppException e) {
    if (e is NoInternetException) return 'No internet connection.\nCheck your network to see reviews.';
    if (e is TimeoutException) return 'Loading reviews timed out.\nPlease try again.';
    if (e is ServerException) return 'Server error (${e.statusCode}).\nPlease try again later.';
    return 'Could not load reviews.\nPlease try again.';
  }

  String _messageForSubmit(AppException e) {
    if (e is NoInternetException) return 'No internet connection.\nYour review was not submitted.';
    if (e is TimeoutException) return 'Submission timed out.\nPlease try again.';
    return 'Failed to submit your review.\nPlease try again.';
  }

  String _messageForDelete(AppException e) {
    if (e is NoInternetException) return 'No internet connection.\nCould not delete review.';
    return 'Failed to delete review.\nPlease try again.';
  }
}