// data/admin_courses_repo.dart

import 'package:e_learning/core/erros/network_exception_handler.dart';
import 'package:e_learning/features/courses/data/model/courses.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminCoursesRepo {
  final _db = Supabase.instance.client;

  Future<List<CourseModel>> fetchAllCourses() async {
    try {
      final list =
          await _db.from('courses').select().order('title') as List;
      final courses = list
          .map((e) => CourseModel.fromJson(e as Map<String, dynamic>))
          .toList();

      if (courses.isEmpty) return [];

      final ids = courses.map((c) => c.id).toList();
      final videos =
          await _db.from('videos').select().inFilter('course_id', ids)
              as List;

      final Map<String, List<VideoModel>> map = {};
      for (final v in videos) {
        final video = VideoModel.fromJson(v as Map<String, dynamic>);
        map.putIfAbsent(video.courseId, () => []).add(video);
      }

      return courses
          .map((c) => c.copyWith(videos: map[c.id] ?? []))
          .toList();
    } catch (e) {
      throw NetworkExceptionHandler.handle(e);
    }
  }

  Future<String?> createCourse({
    required String title,
    required String category,
    required String instructor,
    required String description,
    required String thumbnailUrl,
    required String duration,
    required String level,
    required double rating,
    required bool isFeatured,
  }) async {
    try {
      final res = await _db
          .from('courses')
          .insert({
            'title': title,
            'category': category,
            'instructor': instructor,
            'description': description,
            'thumbnail_url': thumbnailUrl,
            'duration': duration,
            'level': level,
            'rating': rating,
            'is_featured': isFeatured,
            'students_count': 0,
            'lessons_count': 0,
          })
          .select('id')
          .single();
      return (res as Map<String, dynamic>)['id'] as String;
    } catch (e) {
      throw NetworkExceptionHandler.handle(e);
    }
  }

  Future<bool> updateCourse({
    required String courseId,
    required String title,
    required String category,
    required String instructor,
    required String description,
    required String thumbnailUrl,
    required String duration,
    required String level,
    required double rating,
    required bool isFeatured,
  }) async {
    try {
      await _db.from('courses').update({
        'title': title,
        'category': category,
        'instructor': instructor,
        'description': description,
        'thumbnail_url': thumbnailUrl,
        'duration': duration,
        'level': level,
        'rating': rating,
        'is_featured': isFeatured,
      }).eq('id', courseId);
      return true;
    } catch (e) {
      throw NetworkExceptionHandler.handle(e);
    }
  }

  Future<bool> deleteCourse(String courseId) async {
    try {
      await _db.from('courses').delete().eq('id', courseId);
      return true;
    } catch (e) {
      throw NetworkExceptionHandler.handle(e);
    }
  }

  Future<String?> addVideo({
    required String courseId,
    required String title,
    required String duration,
    required String videoUrl,
    required bool isLocked,
  }) async {
    try {
      final res = await _db
          .from('videos')
          .insert({
            'course_id': courseId,
            'title': title,
            'duration': duration,
            'video_url': videoUrl,
            'is_locked': isLocked,
            'is_watched': false,
          })
          .select('id')
          .single();

      final countRes = await _db
          .from('videos')
          .select('id')
          .eq('course_id', courseId);
      await _db
          .from('courses')
          .update({'lessons_count': (countRes as List).length})
          .eq('id', courseId);

      return (res as Map<String, dynamic>)['id'] as String;
    } catch (e) {
      throw NetworkExceptionHandler.handle(e);
    }
  }

  Future<bool> deleteVideo(String videoId, String courseId) async {
    try {
      await _db.from('videos').delete().eq('id', videoId);
      final countRes = await _db
          .from('videos')
          .select('id')
          .eq('course_id', courseId);
      await _db
          .from('courses')
          .update({'lessons_count': (countRes as List).length})
          .eq('id', courseId);
      return true;
    } catch (e) {
      throw NetworkExceptionHandler.handle(e);
    }
  }
}