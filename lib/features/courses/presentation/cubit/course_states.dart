import 'package:e_learning/core/erros/app_exceptions.dart';
import 'package:e_learning/features/courses/data/model/courses.dart';

abstract class CoursesState {}

class CoursesInitial extends CoursesState {}

class CoursesLoading extends CoursesState {}

class CoursesLoaded extends CoursesState {
  final List<CourseModel> courses;
  CoursesLoaded(this.courses);
}

class CoursesError extends CoursesState {
  final String message;
  final AppException? exception;
  CoursesError(this.message, {this.exception});
}