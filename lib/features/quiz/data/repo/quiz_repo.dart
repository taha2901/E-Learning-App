// ─────────────────────────────────────────────
// quiz_repo.dart  —  All Supabase calls live here
// ─────────────────────────────────────────────

import 'package:e_learning/core/erros/network_exception_handler.dart';
import 'package:e_learning/features/quiz/data/model/quiz_model.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QuizRepo {
  final SupabaseClient _db = Supabase.instance.client;

  // ── Student ───────────────────────────────────────────────────────────────

  Future<QuizModel?> fetchQuizForVideo(String videoId) async {
    try {
      final res = await _db
          .from('quizzes')
          .select('*, quiz_questions(*)')
          .eq('video_id', videoId)
          .maybeSingle();
      if (res == null) return null;
      return QuizModel.fromJson(res as Map<String, dynamic>);
    } catch (e) {
      throw NetworkExceptionHandler.handle(e);
    }
  }

  Future<QuizResult?> fetchUserResult(String userId, String quizId) async {
    try {
      final res = await _db
          .from('quiz_results')
          .select()
          .eq('user_id', userId)
          .eq('quiz_id', quizId)
          .maybeSingle();
      if (res == null) return null;
      final r = res as Map<String, dynamic>;
      return QuizResult(
        userId: userId,
        quizId: quizId,
        score: r['score'],
        total: r['total'],
        percentage: r['percentage'],
        passed: r['passed'],
      );
    } catch (e) {
      throw NetworkExceptionHandler.handle(e);
    }
  }

  Future<void> saveResult(QuizResult result) async {
    try {
      await _db.from('quiz_results').upsert(
        {
          'user_id': result.userId,
          'quiz_id': result.quizId,
          'score': result.score,
          'total': result.total,
          'percentage': result.percentage,
          'passed': result.passed,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id,quiz_id',
      );
    } catch (e) {
      try {
        await _db.from('quiz_results').insert({
          'user_id': result.userId,
          'quiz_id': result.quizId,
          'score': result.score,
          'total': result.total,
          'percentage': result.percentage,
          'passed': result.passed,
        });
      } catch (e2) {
        // silent — result save failure shouldn't block the quiz flow
        debugPrint('saveResult error: $e2');
      }
    }
  }

  // ── Admin ─────────────────────────────────────────────────────────────────

  Future<List<QuizModel>> fetchAllQuizzes() async {
    try {
      final list = await _db
          .from('quizzes')
          .select('*, quiz_questions(*)')
          .order('created_at', ascending: false) as List;
      return list
          .map((e) => QuizModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw NetworkExceptionHandler.handle(e);
    }
  }

  Future<List<Map<String, dynamic>>> fetchAllCourses() async {
    try {
      final res = await _db
          .from('courses')
          .select('id, title')
          .order('title') as List;
      return res.cast<Map<String, dynamic>>();
    } catch (e) {
      throw NetworkExceptionHandler.handle(e);
    }
  }

  Future<List<Map<String, dynamic>>> fetchVideosForCourse(
      String courseId) async {
    try {
      final res = await _db
          .from('videos')
          .select('id, title')
          .eq('course_id', courseId)
          .order('title') as List;
      return res.cast<Map<String, dynamic>>();
    } catch (e) {
      throw NetworkExceptionHandler.handle(e);
    }
  }

  Future<String?> createQuiz({
    required String videoId,
    required String courseId,
    required String title,
    required String description,
    required int passScore,
  }) async {
    try {
      final res = await _db.from('quizzes').insert({
        'video_id': videoId,
        'course_id': courseId,
        'title': title,
        'description': description,
        'pass_score': passScore,
      }).select('id').single();
      return (res as Map<String, dynamic>)['id'] as String;
    } catch (e) {
      throw NetworkExceptionHandler.handle(e);
    }
  }

  Future<void> addQuestion({
    required String quizId,
    required String question,
    required String optionA,
    required String optionB,
    required String optionC,
    required String optionD,
    required String correctAnswer,
    required int orderIndex,
  }) async {
    try {
      await _db.from('quiz_questions').insert({
        'quiz_id': quizId,
        'question': question,
        'option_a': optionA,
        'option_b': optionB,
        'option_c': optionC,
        'option_d': optionD,
        'correct_answer': correctAnswer,
        'order_index': orderIndex,
      });
    } catch (e) {
      throw NetworkExceptionHandler.handle(e);
    }
  }

  Future<void> deleteQuiz(String quizId) async {
    try {
      await _db.from('quizzes').delete().eq('id', quizId);
    } catch (e) {
      throw NetworkExceptionHandler.handle(e);
    }
  }

  Future<void> deleteQuestion(String questionId) async {
    try {
      await _db.from('quiz_questions').delete().eq('id', questionId);
    } catch (e) {
      throw NetworkExceptionHandler.handle(e);
    }
  }
}
