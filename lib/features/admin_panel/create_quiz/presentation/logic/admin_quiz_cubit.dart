// ─────────────────────────────────────────────
// admin_quiz_cubit.dart  —  Admin quiz logic ONLY
// ─────────────────────────────────────────────

import 'package:bloc/bloc.dart';
import 'package:e_learning/core/erros/app_exceptions.dart';
import 'package:e_learning/core/erros/network_exception_handler.dart';
import 'package:e_learning/features/admin_panel/create_quiz/presentation/logic/admin_quiz_states.dart';
import 'package:e_learning/features/quiz/data/model/quiz_model.dart';
import 'package:e_learning/features/quiz/data/repo/quiz_repo.dart';

class AdminQuizCubit extends Cubit<AdminQuizState> {
  final QuizRepo _repo;

  AdminQuizCubit(this._repo) : super(AdminQuizInitial());

  // ── Fetch courses (for CreateQuizScreen dropdown) ────────────────────────
  Future<List<Map<String, dynamic>>> fetchCourses() async {
    return await _repo.fetchAllCourses();
  }

  // ── Load all quizzes ──────────────────────────────────────────────────────
  Future<void> loadAllQuizzes() async {
    emit(AdminQuizLoading());
    try {
      final quizzes = await _repo.fetchAllQuizzes();
      emit(AdminQuizLoaded(quizzes));
    } on AppException catch (e) {
      emit(AdminQuizError(e));
    } catch (e) {
      emit(AdminQuizError(NetworkExceptionHandler.handle(e)));
    }
  }

  // ── Load videos for a course (used in CreateQuizScreen dropdown) ──────────
  Future<void> loadVideosForCourse(String courseId) async {
    emit(AdminVideosLoading());
    try {
      final videos = await _repo.fetchVideosForCourse(courseId);
      emit(AdminVideosLoaded(videos));
    } on AppException catch (e) {
      // Non-fatal — emit empty list so the UI can still show the dropdown
      emit(AdminVideosLoaded([]));
      rethrow;
    } catch (e) {
      emit(AdminVideosLoaded([]));
    }
  }

  // ── Create quiz ───────────────────────────────────────────────────────────
  Future<QuizModel?> createQuiz({
    required String videoId,
    required String courseId,
    required String title,
    required String description,
    required int passScore,
  }) async {
    try {
      final quizId = await _repo.createQuiz(
        videoId: videoId,
        courseId: courseId,
        title: title,
        description: description,
        passScore: passScore,
      );
      if (quizId == null) return null;

      final quiz = QuizModel(
        id: quizId,
        videoId: videoId,
        courseId: courseId,
        title: title,
        description: description,
        passScore: passScore,
        questions: [],
      );
      emit(AdminQuizSaved(quiz));
      return quiz;
    } on AppException {
      rethrow;
    } catch (e) {
      throw NetworkExceptionHandler.handle(e);
    }
  }

  // ── Add question ──────────────────────────────────────────────────────────
  Future<void> addQuestion({
    required String quizId,
    required String videoId,
    required String question,
    required String optionA,
    required String optionB,
    required String optionC,
    required String optionD,
    required String correctAnswer,
    required int orderIndex,
  }) async {
    try {
      await _repo.addQuestion(
        quizId: quizId,
        question: question,
        optionA: optionA,
        optionB: optionB,
        optionC: optionC,
        optionD: optionD,
        correctAnswer: correctAnswer,
        orderIndex: orderIndex,
      );
      // Re-fetch the quiz so the UI gets the real saved question (with DB id)
      final updated = await _repo.fetchQuizForVideo(videoId);
      if (updated != null) emit(AdminQuizSaved(updated));
    } on AppException {
      rethrow;
    } catch (e) {
      throw NetworkExceptionHandler.handle(e);
    }
  }

  // ── Delete question ───────────────────────────────────────────────────────
  Future<void> deleteQuestion({
    required String questionId,
    required String videoId,
  }) async {
    try {
      await _repo.deleteQuestion(questionId);
      final updated = await _repo.fetchQuizForVideo(videoId);
      if (updated != null) emit(AdminQuizSaved(updated));
    } on AppException {
      rethrow;
    } catch (e) {
      throw NetworkExceptionHandler.handle(e);
    }
  }

  // ── Delete quiz ───────────────────────────────────────────────────────────
  Future<void> deleteQuiz(String quizId) async {
    try {
      await _repo.deleteQuiz(quizId);
      await loadAllQuizzes();
    } on AppException {
      rethrow;
    } catch (e) {
      throw NetworkExceptionHandler.handle(e);
    }
  }
}
