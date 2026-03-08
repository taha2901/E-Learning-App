import 'package:e_learning/core/erros/network_exception_handler.dart';
import 'package:e_learning/features/courses/data/model/review_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _kTimeout = Duration(seconds: 15);

class ReviewRepo {
  final SupabaseClient _db = Supabase.instance.client;

  Future<List<ReviewModel>> fetchReviews(String courseId) async {
    try {
      final reviewsRes = await _db
          .from('course_reviews')
          .select('id, user_id, course_id, rating, comment, created_at')
          .eq('course_id', courseId)
          .order('created_at', ascending: false)
          .timeout(_kTimeout) as List;

      if (reviewsRes.isEmpty) return [];

      final userIds = reviewsRes
          .map((e) => (e as Map<String, dynamic>)['user_id'] as String)
          .toSet()
          .toList();

      Map<String, Map<String, dynamic>> profilesMap = {};
      try {
        final profilesRes = await _db
            .from('profiles')
            .select('user_id, name, avatar_url')
            .inFilter('user_id', userIds)
            .timeout(_kTimeout) as List;
        for (final p in profilesRes) {
          final profile = p as Map<String, dynamic>;
          profilesMap[profile['user_id'] as String] = profile;
        }
      } catch (_) {}

      return reviewsRes.map((e) {
        final review = Map<String, dynamic>.from(e as Map<String, dynamic>);
        review['profiles'] = profilesMap[review['user_id'] as String] ?? {};
        return ReviewModel.fromJson(review);
      }).toList();
    } catch (e) {
      // ✅ throw بدل return [] عشان ReviewCubit يعمل ReviewError بالرسالة الصح
      throw NetworkExceptionHandler.handle(e);
    }
  }

  Future<bool> submitReview({
    required String userId,
    required String courseId,
    required double rating,
    required String comment,
  }) async {
    try {
      await _db.from('course_reviews').upsert(
        {
          'user_id': userId,
          'course_id': courseId,
          'rating': rating,
          'comment': comment,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id,course_id',
      ).timeout(_kTimeout);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> deleteReview(String reviewId) async {
    try {
      await _db
          .from('course_reviews')
          .delete()
          .eq('id', reviewId)
          .timeout(_kTimeout);
    } catch (_) {}
  }

  Future<double> fetchCourseRating(String courseId) async {
    try {
      final res = await _db
          .from('courses')
          .select('rating')
          .eq('id', courseId)
          .single()
          .timeout(_kTimeout) as Map;
      return (res['rating'] as num?)?.toDouble() ?? 0.0;
    } catch (_) {
      return 0.0;
    }
  }

  Future<bool> isEnrolled(String userId, String courseId) async {
    try {
      final res = await _db
          .from('enrollments')
          .select('id')
          .eq('user_id', userId)
          .eq('course_id', courseId)
          .maybeSingle()
          .timeout(_kTimeout);
      return res != null;
    } catch (_) {
      return false;
    }
  }
}