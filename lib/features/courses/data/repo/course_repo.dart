import 'package:e_learning/features/courses/data/model/courses.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CoursesRepo {
  final SupabaseClient _client = Supabase.instance.client;

  // ── helper: جيب videos لكورس معين ────────────────────────────────────────
  Future<List<VideoModel>> _fetchVideosForCourse(String courseId) async {
    try {
      final list = await _client
          .from('videos')
          .select()
          .eq('course_id', courseId) as List<dynamic>;
      return list
          .map((e) => VideoModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── helper: جيب videos لكورسات كتير دفعة واحدة ───────────────────────────
  Future<Map<String, List<VideoModel>>> _fetchVideosForCourses(
      List<String> courseIds) async {
    if (courseIds.isEmpty) return {};
    try {
      final list = await _client
          .from('videos')
          .select()
          .inFilter('course_id', courseIds) as List<dynamic>;

      final Map<String, List<VideoModel>> map = {};
      for (final item in list) {
        final v = VideoModel.fromJson(item as Map<String, dynamic>);
        map.putIfAbsent(v.courseId, () => []).add(v);
      }
      return map;
    } catch (_) {
      return {};
    }
  }

  // ── Fetch All Courses ─────────────────────────────────────────────────────
  Future<List<CourseModel>> fetchCourses() async {
    try {
      // بدون videos join عشان نتجنب الـ ambiguous relationship error
      final list = await _client.from('courses').select() as List<dynamic>;
      final courses = list
          .map((e) => CourseModel.fromJson(e as Map<String, dynamic>))
          .toList();

      // جيب الفيديوهات منفصلة
      final ids = courses.map((c) => c.id).toList();
      final videosMap = await _fetchVideosForCourses(ids);

      return courses.map((c) {
        final videos = videosMap[c.id] ?? [];
        return c.copyWith(videos: videos);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch courses: $e');
    }
  }

  // ── Fetch Featured Courses ────────────────────────────────────────────────
  Future<List<CourseModel>> fetchFeaturedCourses() async {
    try {
      final list = await _client
          .from('courses')
          .select()
          .eq('is_featured', true) as List<dynamic>;
      final courses = list
          .map((e) => CourseModel.fromJson(e as Map<String, dynamic>))
          .toList();

      final ids = courses.map((c) => c.id).toList();
      final videosMap = await _fetchVideosForCourses(ids);

      return courses.map((c) => c.copyWith(videos: videosMap[c.id] ?? [])).toList();
    } catch (e) {
      throw Exception('Failed to fetch featured courses: $e');
    }
  }

  // ── Fetch My Enrolled Courses ─────────────────────────────────────────────
  Future<List<CourseModel>> fetchMyCourses(String userId) async {
    try {
      final enrollments = await _client
          .from('enrollments')
          .select('course_id')
          .eq('user_id', userId) as List<dynamic>;

      if (enrollments.isEmpty) return [];

      final courseIds = enrollments
          .map((e) => (e as Map<String, dynamic>)['course_id'] as String)
          .toList();

      final courseList = await _client
          .from('courses')
          .select()
          .inFilter('id', courseIds) as List<dynamic>;

      final courses = courseList
          .map((e) => CourseModel.fromJson(e as Map<String, dynamic>))
          .toList();

      final videosMap = await _fetchVideosForCourses(courseIds);

      return courses.map((c) => c.copyWith(videos: videosMap[c.id] ?? [])).toList();
    } catch (e) {
      throw Exception('Failed to fetch my courses: $e');
    }
  }

  // ── Enroll ────────────────────────────────────────────────────────────────
  Future<void> enrollInCourse(String userId, String courseId) async {
    try {
      await _client.from('enrollments').insert({
        'user_id': userId,
        'course_id': courseId,
        'enrolled_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to enroll: $e');
    }
  }

  // ── Wishlist ──────────────────────────────────────────────────────────────
  Future<void> addToWishlist(String userId, String courseId) async {
    try {
      await _client
          .from('wishlist')
          .upsert({'user_id': userId, 'course_id': courseId});
    } catch (e) {
      throw Exception('Failed to add to wishlist: $e');
    }
  }

  Future<void> removeFromWishlist(String userId, String courseId) async {
    try {
      await _client
          .from('wishlist')
          .delete()
          .eq('user_id', userId)
          .eq('course_id', courseId);
    } catch (e) {
      throw Exception('Failed to remove from wishlist: $e');
    }
  }

  Future<List<CourseModel>> fetchWishlist(String userId) async {
    try {
      final list = await _client
          .from('wishlist')
          .select('course_id')
          .eq('user_id', userId) as List<dynamic>;

      if (list.isEmpty) return [];

      final ids = list
          .map((e) => (e as Map<String, dynamic>)['course_id'] as String)
          .toList();

      final courseList = await _client
          .from('courses')
          .select()
          .inFilter('id', ids) as List<dynamic>;

      final courses = courseList
          .map((e) => CourseModel.fromJson(e as Map<String, dynamic>))
          .toList();

      final videosMap = await _fetchVideosForCourses(ids);

      return courses.map((c) => c.copyWith(videos: videosMap[c.id] ?? [])).toList();
    } catch (e) {
      throw Exception('Failed to fetch wishlist: $e');
    }
  }

  // ── Video Progress ────────────────────────────────────────────────────────
  Future<void> markVideoWatched(String userId, String videoId) async {
    try {
      await _client.from('video_progress').upsert({
        'user_id': userId,
        'video_id': videoId,
        'watched': true,
        'watched_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to mark video as watched: $e');
    }
  }

  Future<Set<String>> fetchWatchedVideoIds(
      String userId, String courseId) async {
    try {
      final videoIds = await _client
          .from('videos')
          .select('id')
          .eq('course_id', courseId) as List<dynamic>;

      if (videoIds.isEmpty) return {};

      final ids = videoIds
          .map((e) => (e as Map<String, dynamic>)['id'] as String)
          .toList();

      final watched = await _client
          .from('video_progress')
          .select('video_id')
          .eq('user_id', userId)
          .inFilter('video_id', ids) as List<dynamic>;

      return watched
          .map((e) => (e as Map<String, dynamic>)['video_id'] as String)
          .toSet();
    } catch (_) {
      return {};
    }
  }
}