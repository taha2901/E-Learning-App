import 'package:e_learning/core/erros/app_exceptions.dart';
import 'package:e_learning/features/courses/data/model/courses.dart';

abstract class HomeState {}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<CourseModel> courses;
  final List<CourseModel> featuredCourses;
  final String selectedCategory;
  final String searchQuery;

  HomeLoaded({
    required this.courses,
    required this.featuredCourses,
    required this.selectedCategory,
    required this.searchQuery,
  });

  HomeLoaded copyWith({
    List<CourseModel>? courses,
    List<CourseModel>? featuredCourses,
    String? selectedCategory,
    String? searchQuery,
  }) =>
      HomeLoaded(
        courses: courses ?? this.courses,
        featuredCourses: featuredCourses ?? this.featuredCourses,
        selectedCategory: selectedCategory ?? this.selectedCategory,
        searchQuery: searchQuery ?? this.searchQuery,
      );
}

class HomeError extends HomeState {
  final String message;
  final AppException? exception;
  HomeError(this.message, {this.exception});
}