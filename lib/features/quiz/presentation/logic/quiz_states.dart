// ─────────────────────────────────────────────
// quiz_states.dart  —  Student quiz states ONLY
// ─────────────────────────────────────────────

import 'package:e_learning/core/erros/app_exceptions.dart';
import 'package:e_learning/features/quiz/data/model/quiz_model.dart';

abstract class QuizState {}

/// Initial state before anything loads
class QuizInitial extends QuizState {}

/// Loading quiz from backend
class QuizLoading extends QuizState {}

/// Quiz loaded, waiting for student to start
class QuizLoaded extends QuizState {
  final QuizModel quiz;
  final QuizResult? previousResult;
  QuizLoaded({required this.quiz, this.previousResult});
}

/// No quiz found for this video
class QuizNotFound extends QuizState {}

/// Quiz is actively in progress
class QuizInProgress extends QuizState {
  final QuizModel quiz;
  final int currentIndex;
  final int secondsLeft;
  final String? selectedAnswer;
  final bool answered;
  final Map<int, String> answers;

  QuizInProgress({
    required this.quiz,
    required this.currentIndex,
    required this.secondsLeft,
    this.selectedAnswer,
    this.answered = false,
    this.answers = const {},
  });

  QuizInProgress copyWith({
    int? currentIndex,
    int? secondsLeft,
    String? selectedAnswer,
    bool? answered,
    Map<int, String>? answers,
    bool clearSelectedAnswer = false,
  }) {
    return QuizInProgress(
      quiz: quiz,
      currentIndex: currentIndex ?? this.currentIndex,
      secondsLeft: secondsLeft ?? this.secondsLeft,
      selectedAnswer:
          clearSelectedAnswer ? null : selectedAnswer ?? this.selectedAnswer,
      answered: answered ?? this.answered,
      answers: answers ?? this.answers,
    );
  }
}

/// Quiz finished — carries final result
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

/// Non-fatal or fatal quiz error
class QuizError extends QuizState {
  final AppException exception;
  QuizError(this.exception);
}
