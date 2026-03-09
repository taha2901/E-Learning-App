// ─────────────────────────────────────────────
// admin_quiz_states.dart  —  Admin quiz states
// ─────────────────────────────────────────────

import 'package:e_learning/core/erros/app_exceptions.dart';
import 'package:e_learning/features/quiz/data/model/quiz_model.dart';

abstract class AdminQuizState {}

/// Initial before any load
class AdminQuizInitial extends AdminQuizState {}

/// Loading list of all quizzes
class AdminQuizLoading extends AdminQuizState {}

/// All quizzes loaded successfully
class AdminQuizLoaded extends AdminQuizState {
  final List<QuizModel> quizzes;
  AdminQuizLoaded(this.quizzes);
}

/// Error loading quizzes
class AdminQuizError extends AdminQuizState {
  final AppException exception;
  AdminQuizError(this.exception);
}

/// A quiz was created or updated — carries the updated quiz
class AdminQuizSaved extends AdminQuizState {
  final QuizModel quiz;
  AdminQuizSaved(this.quiz);
}

/// Loading videos for the selected course (used in CreateQuizScreen)
class AdminVideosLoading extends AdminQuizState {}

/// Videos loaded for the selected course
class AdminVideosLoaded extends AdminQuizState {
  final List<Map<String, dynamic>> videos;
  AdminVideosLoaded(this.videos);
}
