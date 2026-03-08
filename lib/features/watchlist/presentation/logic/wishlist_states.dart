import 'package:e_learning/features/courses/data/model/courses.dart';

abstract class WishlistState {}

class WishlistInitial extends WishlistState {}

class WishlistLoading extends WishlistState {}

class WishlistLoaded extends WishlistState {
  final List<CourseModel> courses;
  final Set<String> savedIds;

  WishlistLoaded({required this.courses, required this.savedIds});

  bool isSaved(String courseId) => savedIds.contains(courseId);

  WishlistLoaded copyWith({
    List<CourseModel>? courses,
    Set<String>? savedIds,
  }) {
    return WishlistLoaded(
      courses: courses ?? this.courses,
      savedIds: savedIds ?? this.savedIds,
    );
  }
}

class WishlistError extends WishlistState {
  final String message;
  WishlistError(this.message);
}