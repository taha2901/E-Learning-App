import 'package:e_learning/features/courses/data/model/courses.dart';

abstract class HomeState {}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeError extends HomeState {
  final String message;
  HomeError(this.message);
}

class HomeLoaded extends HomeState {
  final List<CourseModel> courses;
  final List<CourseModel> featuredCourses;
  final String selectedCategory;
  final String searchQuery;

  HomeLoaded({
    required this.courses,
    required this.featuredCourses,
    this.selectedCategory = 'All',
    this.searchQuery = '',
  });

  HomeLoaded copyWith({
    List<CourseModel>? courses,
    List<CourseModel>? featuredCourses,
    String? selectedCategory,
    String? searchQuery,
  }) {
    return HomeLoaded(
      courses: courses ?? this.courses,
      featuredCourses: featuredCourses ?? this.featuredCourses,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}