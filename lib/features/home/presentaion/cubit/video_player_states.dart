import 'package:e_learning/core/erros/app_exceptions.dart';
import 'package:e_learning/features/quiz/data/model/quiz_model.dart';

abstract class VideoPlayerState {}

class VideoPlayerInitial extends VideoPlayerState {}

/// جاري تحميل الكويز
class VideoQuizLoading extends VideoPlayerState {}

/// الكويز اتحمل — quiz ممكن يكون null لو مفيش كويز للفيديو ده
class VideoQuizLoaded extends VideoPlayerState {
  final QuizModel? quiz;
  final QuizResult? previousResult;

  VideoQuizLoaded({required this.quiz, this.previousResult});
}

/// حصل error أثناء تحميل الكويز
class VideoQuizError extends VideoPlayerState {
  final AppException exception;
  VideoQuizError(this.exception);
}
