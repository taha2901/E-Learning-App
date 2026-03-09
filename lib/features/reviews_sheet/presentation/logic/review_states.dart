import 'package:e_learning/features/courses/data/model/review_model.dart';

abstract class ReviewState {}
class ReviewInitial extends ReviewState {}
class ReviewLoading extends ReviewState {}
class ReviewSubmitting extends ReviewState {}

class ReviewLoaded extends ReviewState {
  final List<ReviewModel> reviews;
  final ReviewSummary summary;
  final ReviewModel? myReview;
  ReviewLoaded({required this.reviews, required this.summary, this.myReview});
}

class ReviewError extends ReviewState {
  final String message;
  ReviewError(this.message);
}