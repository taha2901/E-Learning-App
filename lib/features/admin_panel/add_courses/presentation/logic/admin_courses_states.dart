import 'package:e_learning/core/erros/app_exceptions.dart';
import 'package:e_learning/features/courses/data/model/courses.dart';

abstract class AdminCoursesState {}

class AdminCoursesInitial extends AdminCoursesState {}

// ── Loading the full list ─────────────────────────────────
class AdminCoursesLoading extends AdminCoursesState {}

class AdminCoursesLoaded extends AdminCoursesState {
  final List<CourseModel> courses;
  AdminCoursesLoaded(this.courses);
}

class AdminCoursesError extends AdminCoursesState {
  final AppException exception;
  AdminCoursesError(this.exception);
}

// ── Action in progress (create / update / delete) ─────────
// الـ courses list بتفضل موجودة عشان الـ UI ميتلخبطش
class AdminCoursesActionLoading extends AdminCoursesState {
  final List<CourseModel> courses;
  AdminCoursesActionLoading(this.courses);
}

// Action خلص بنجاح
class AdminCoursesActionSuccess extends AdminCoursesState {
  final List<CourseModel> courses;
  final String message;
  AdminCoursesActionSuccess({required this.courses, required this.message});
}

// Action فشل — بنرجع الـ courses الأصلية
class AdminCoursesActionError extends AdminCoursesState {
  final List<CourseModel> courses;
  final AppException exception;
  AdminCoursesActionError({required this.courses, required this.exception});
}
