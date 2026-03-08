// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// review_model.dart
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class ReviewModel {
  final String id;
  final String courseId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final double rating;
  final String comment;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.courseId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    // profile data joined
    final profile = json['profiles'] as Map<String, dynamic>? ?? {};
    return ReviewModel(
      id: json['id'] as String,
      courseId: json['course_id'] as String,
      userId: json['user_id'] as String,
      userName: profile['name'] as String? ?? 'Anonymous',
      userAvatar: profile['avatar_url'] as String?,
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class ReviewSummary {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> distribution; // star → count

  const ReviewSummary({
    required this.averageRating,
    required this.totalReviews,
    required this.distribution,
  });

  factory ReviewSummary.fromReviews(List<ReviewModel> reviews) {
    if (reviews.isEmpty) {
      return const ReviewSummary(
        averageRating: 0,
        totalReviews: 0,
        distribution: {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
      );
    }
    final dist = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    double sum = 0;
    for (final r in reviews) {
      sum += r.rating;
      final star = r.rating.round().clamp(1, 5);
      dist[star] = (dist[star] ?? 0) + 1;
    }
    return ReviewSummary(
      averageRating: sum / reviews.length,
      totalReviews: reviews.length,
      distribution: dist,
    );
  }
}