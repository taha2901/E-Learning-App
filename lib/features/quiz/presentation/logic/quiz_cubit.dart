// ─────────────────────────────────────────────
// quiz_cubit.dart  —  Student quiz logic ONLY
// ─────────────────────────────────────────────

import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:e_learning/core/erros/app_exceptions.dart';
import 'package:e_learning/core/erros/network_exception_handler.dart';
import 'package:e_learning/features/notificatio/data/model/notification_model.dart';
import 'package:e_learning/features/notificatio/data/repo/notification_repo.dart';
import 'package:e_learning/features/quiz/data/model/quiz_model.dart';
import 'package:e_learning/features/quiz/data/repo/quiz_repo.dart';
import 'package:e_learning/features/quiz/presentation/logic/quiz_states.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QuizCubit extends Cubit<QuizState> {
  final QuizRepo _repo;
  Timer? _timer;
  static const _totalSeconds = 30;

  QuizCubit(this._repo) : super(QuizInitial());

  // ── Load quiz for a video ─────────────────────────────────────────────────
  Future<void> loadQuizForVideo(String videoId) async {
    emit(QuizLoading());
    try {
      final quiz = await _repo.fetchQuizForVideo(videoId);
      if (quiz == null) {
        emit(QuizNotFound());
        return;
      }
      final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
      QuizResult? prev;
      if (userId.isNotEmpty) {
        prev = await _repo.fetchUserResult(userId, quiz.id);
      }
      emit(QuizLoaded(quiz: quiz, previousResult: prev));
    } on AppException catch (e) {
      emit(QuizError(e));
    } catch (e) {
      emit(QuizError(NetworkExceptionHandler.handle(e)));
    }
  }

  // ── Start quiz ────────────────────────────────────────────────────────────
  void startQuiz(QuizModel quiz) {
    _cancelTimer();
    emit(QuizInProgress(
      quiz: quiz,
      currentIndex: 0,
      secondsLeft: _totalSeconds,
    ));
    _startTimer();
  }

  // ── Select answer ─────────────────────────────────────────────────────────
  void selectAnswer(String letter) {
    if (state is! QuizInProgress) return;
    final s = state as QuizInProgress;
    if (s.answered) return;

    _cancelTimer();
    final newAnswers = Map<int, String>.from(s.answers)..[s.currentIndex] = letter;

    emit(s.copyWith(
      selectedAnswer: letter,
      answered: true,
      answers: newAnswers,
    ));

    Future.delayed(const Duration(milliseconds: 900), _nextQuestion);
  }

  // ── Next question ─────────────────────────────────────────────────────────
  void _nextQuestion() {
    if (state is! QuizInProgress) return;
    final s = state as QuizInProgress;

    if (s.currentIndex < s.quiz.questions.length - 1) {
      _cancelTimer();
      emit(s.copyWith(
        currentIndex: s.currentIndex + 1,
        clearSelectedAnswer: true,
        answered: false,
        secondsLeft: _totalSeconds,
      ));
      _startTimer();
    } else {
      _finishQuiz();
    }
  }

  // ── Time expired ──────────────────────────────────────────────────────────
  void _onTimeExpired() {
    if (state is! QuizInProgress) return;
    final s = state as QuizInProgress;
    if (!s.answered) _nextQuestion();
  }

  // ── Finish quiz ───────────────────────────────────────────────────────────
  Future<void> _finishQuiz() async {
    if (state is! QuizInProgress) return;
    final s = state as QuizInProgress;
    _cancelTimer();

    final questions = s.quiz.questions;
    int score = 0;
    for (int i = 0; i < questions.length; i++) {
      if (s.answers[i] == questions[i].correctAnswer) score++;
    }
    final pct = ((score / questions.length) * 100).round();
    final passed = pct >= s.quiz.passScore;

    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    if (userId.isNotEmpty) {
      // silent — save result shouldn't block the flow
      try {
        await _repo.saveResult(QuizResult(
          userId: userId,
          quizId: s.quiz.id,
          score: score,
          total: questions.length,
          percentage: pct,
          passed: passed,
        ));
      } catch (_) {}

      // silent — notification shouldn't block the flow
      try {
        NotificationRepo().createNotification(
          userId: userId,
          title: passed ? '🎉 Quiz Passed!' : '📚 Keep Practicing',
          body: passed
              ? 'You scored $pct% on "${s.quiz.title}". Amazing work!'
              : 'You scored $pct% on "${s.quiz.title}". Try again!',
          type: passed ? NotificationType.achievement : NotificationType.quiz,
          metadata: {'quiz_id': s.quiz.id, 'score': pct},
        );
      } catch (_) {}
    }

    emit(QuizFinished(
      quiz: s.quiz,
      score: score,
      total: questions.length,
      percentage: pct,
      passed: passed,
      answers: s.answers,
    ));
  }

  // ── Retry quiz ────────────────────────────────────────────────────────────
  void retryQuiz() {
    if (state is QuizFinished) {
      startQuiz((state as QuizFinished).quiz);
    } else if (state is QuizLoaded) {
      startQuiz((state as QuizLoaded).quiz);
    }
  }

  // ── Timer ─────────────────────────────────────────────────────────────────
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state is! QuizInProgress) return;
      final s = state as QuizInProgress;
      if (s.secondsLeft <= 1) {
        _cancelTimer();
        _onTimeExpired();
      } else {
        emit(s.copyWith(secondsLeft: s.secondsLeft - 1));
      }
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  Future<void> close() {
    _cancelTimer();
    return super.close();
  }
}
