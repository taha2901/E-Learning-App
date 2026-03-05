class CourseModel {
  final String id;
  final String title;
  final String category;
  final String instructor;
  final String thumbnailUrl;
  final String description;
  final double rating;
  final int studentsCount;
  final int lessonsCount;
  final String duration;
  final String level;
  final bool isEnrolled;
  final bool isFeatured;
  final List<VideoModel> videos;

  CourseModel({
    required this.id,
    required this.title,
    required this.category,
    required this.instructor,
    required this.thumbnailUrl,
    required this.description,
    required this.rating,
    required this.studentsCount,
    required this.lessonsCount,
    required this.duration,
    required this.level,
    this.isEnrolled = false,
    this.isFeatured = false,
    required this.videos,
  });

  // ✅ copyWith عشان نقدر نضيف الـ videos بعدين
  CourseModel copyWith({
    String? id,
    String? title,
    String? category,
    String? instructor,
    String? thumbnailUrl,
    String? description,
    double? rating,
    int? studentsCount,
    int? lessonsCount,
    String? duration,
    String? level,
    bool? isEnrolled,
    bool? isFeatured,
    List<VideoModel>? videos,
  }) {
    return CourseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      instructor: instructor ?? this.instructor,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      description: description ?? this.description,
      rating: rating ?? this.rating,
      studentsCount: studentsCount ?? this.studentsCount,
      lessonsCount: lessonsCount ?? this.lessonsCount,
      duration: duration ?? this.duration,
      level: level ?? this.level,
      isEnrolled: isEnrolled ?? this.isEnrolled,
      isFeatured: isFeatured ?? this.isFeatured,
      videos: videos ?? this.videos,
    );
  }

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['id'],
      title: json['title'],
      category: json['category'],
      instructor: json['instructor'],
      thumbnailUrl: json['thumbnail_url'],
      description: json['description'],
      rating: (json['rating'] as num).toDouble(),
      studentsCount: json['students_count'],
      lessonsCount: json['lessons_count'],
      duration: json['duration'],
      level: json['level'],
      isEnrolled: json['is_enrolled'] ?? false,
      isFeatured: json['is_featured'] ?? false,
      // ✅ لو الـ videos جت مع الـ JSON خذها، لو لأ ابدأ بـ list فاضية
      videos: (json['videos'] as List<dynamic>? ?? [])
          .map((v) => VideoModel.fromJson(v as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ─────────────────────────────────────────────
// Video Model
// ─────────────────────────────────────────────
class VideoModel {
  final String id;
  final String courseId;
  final String title;
  final String duration;
  final String videoUrl;
  final bool isLocked;
  final bool isWatched;

  VideoModel({
    required this.id,
    required this.courseId,
    required this.title,
    required this.duration,
    required this.videoUrl,
    required this.isLocked,
    required this.isWatched,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) => VideoModel(
        id: json['id'],
        courseId: json['course_id'],
        title: json['title'] ?? '',
        duration: json['duration'] ?? '',
        videoUrl: json['video_url'] ?? '',
        isLocked: json['is_locked'] ?? false,
        isWatched: json['is_watched'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'course_id': courseId,
        'title': title,
        'duration': duration,
        'video_url': videoUrl,
        'is_locked': isLocked,
        'is_watched': isWatched,
      };
}