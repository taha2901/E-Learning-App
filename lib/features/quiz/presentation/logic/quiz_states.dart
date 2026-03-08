import 'package:e_learning/core/erros/app_exceptions.dart';
import 'package:e_learning/features/quiz/data/model/quiz_model.dart';

abstract class QuizState {}

class QuizInitial extends QuizState {}

class QuizLoading extends QuizState {}

class QuizNotFound extends QuizState {}

class QuizLoaded extends QuizState {
  final QuizModel quiz;
  final QuizResult? previousResult;
  QuizLoaded({required this.quiz, this.previousResult});
}

class QuizInProgress extends QuizState {
  final QuizModel quiz;
  final int currentIndex;
  final int secondsLeft;
  final Map<int, String> answers;
  final String? selectedAnswer;
  final bool answered;

  QuizInProgress({
    required this.quiz,
    required this.currentIndex,
    required this.secondsLeft,
    this.answers = const {},
    this.selectedAnswer,
    this.answered = false,
  });

  QuizInProgress copyWith({
    int? currentIndex,
    int? secondsLeft,
    Map<int, String>? answers,
    String? selectedAnswer,
    bool? answered,
  }) =>
      QuizInProgress(
        quiz: quiz,
        currentIndex: currentIndex ?? this.currentIndex,
        secondsLeft: secondsLeft ?? this.secondsLeft,
        answers: answers ?? this.answers,
        selectedAnswer: selectedAnswer,
        answered: answered ?? this.answered,
      );
}

class QuizFinished extends QuizState {
  final QuizModel quiz;
  final int score;
  final int total;
  final int percentage;
  final bool passed;
  final Map<int, String> answers;

  QuizFinished({
    required this.quiz,
    required this.score,
    required this.total,
    required this.percentage,
    required this.passed,
    required this.answers,
  });
}

// ── Error state — typed ───────────────────────────────────────────────────────
class QuizError extends QuizState {
  final AppException exception;
  QuizError(this.exception);
}

// ── Admin States ──────────────────────────────────────────────────────────────
class AdminQuizLoading extends QuizState {}

class AdminQuizLoaded extends QuizState {
  final List<QuizModel> quizzes;
  AdminQuizLoaded(this.quizzes);
}

class AdminQuizError extends QuizState {
  final AppException exception;
  AdminQuizError(this.exception);
}

class AdminQuizSaved extends QuizState {
  final QuizModel quiz;
  AdminQuizSaved(this.quiz);
}

class AdminVideosLoading extends QuizState {}

class AdminVideosLoaded extends QuizState {
  final List<Map<String, dynamic>> videos;
  AdminVideosLoaded(this.videos);
}