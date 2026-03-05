
import 'package:e_learning/features/courses/data/model/courses.dart';
import 'package:equatable/equatable.dart';

abstract class CoursesState extends Equatable {
  const CoursesState();

  @override
  List<Object?> get props => [];
}

class CoursesInitial extends CoursesState {}

class CoursesLoading extends CoursesState {}

class CoursesLoaded extends CoursesState {
  final List<CourseModel> courses;
  const CoursesLoaded(this.courses);

  @override
  List<Object?> get props => [courses];
}

class CoursesError extends CoursesState {
  final String message;
  const CoursesError(this.message);

  @override
  List<Object?> get props => [message];
}