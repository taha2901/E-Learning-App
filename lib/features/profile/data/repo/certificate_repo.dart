import 'package:e_learning/core/erros/network_exception_handler.dart';
import 'package:e_learning/features/profile/data/models/certificate_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CertificateRepo {
  final _db = Supabase.instance.client;

  /// بيجيب كل الـ certificates للـ user
  /// بيشوف الكورسات اللي خلصها اليوزر ويبني منها CertificateData
  Future<List<CertificateData>> fetchCertificates(String userId) async {
    try {
      // جيب كل الـ enrollments
      final enrollments = await _db
          .from('enrollments')
          .select('course_id')
          .eq('user_id', userId) as List;

      if (enrollments.isEmpty) return [];

      final courseIds =
          enrollments.map((e) => e['course_id'] as String).toList();

      // جيب الكورسات مع الـ videos
      final courseList = await _db
          .from('courses')
          .select('id, title, instructor')
          .inFilter('id', courseIds) as List;

      final videoList = await _db
          .from('videos')
          .select('id, course_id')
          .inFilter('course_id', courseIds) as List;

      // جيب الـ watched videos للـ user
      final watchedList = await _db
          .from('video_progress')
          .select('video_id, watched_at')
          .eq('user_id', userId)
          .eq('watched', true) as List;

      final watchedIds =
          watchedList.map((e) => e['video_id'] as String).toSet();

      // map: courseId → list of videoIds
      final Map<String, List<String>> courseVideosMap = {};
      for (final v in videoList) {
        courseVideosMap
            .putIfAbsent(v['course_id'] as String, () => [])
            .add(v['id'] as String);
      }

      // map: videoId → watched_at
      final Map<String, DateTime> watchedAtMap = {};
      for (final w in watchedList) {
        watchedAtMap[w['video_id'] as String] =
            DateTime.parse(w['watched_at'] as String);
      }

      final certificates = <CertificateData>[];

      for (final course in courseList) {
        final courseId = course['id'] as String;
        final videos = courseVideosMap[courseId] ?? [];

        // مفيش فيديوهات — مش كورس حقيقي
        if (videos.isEmpty) continue;

        // اليوزر خلص كل الفيديوهات؟
        final allWatched = videos.every((id) => watchedIds.contains(id));
        if (!allWatched) continue;

        // تاريخ الإتمام = آخر فيديو اتشاف
        final completionDate = videos
            .where((id) => watchedAtMap.containsKey(id))
            .map((id) => watchedAtMap[id]!)
            .fold(DateTime(2000), (a, b) => a.isAfter(b) ? a : b);

        // جيب اسم اليوزر
        final profile = await _db
            .from('profiles')
            .select('name')
            .eq('user_id', userId)
            .maybeSingle();
        final studentName =
            (profile?['name'] as String?)?.trim().isNotEmpty == true
                ? profile!['name'] as String
                : 'Student';

        certificates.add(CertificateData(
          studentName: studentName,
          courseName: course['title'] as String,
          instructorName: course['instructor'] as String,
          completionDate: completionDate,
          certificateId: 'CERT-$courseId-$userId'.toUpperCase(),
        ));
      }

      return certificates;
    } catch (e) {
      throw NetworkExceptionHandler.handle(e);
    }
  }
}