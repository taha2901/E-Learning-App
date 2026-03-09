import 'package:bloc/bloc.dart';
import 'package:e_learning/core/erros/app_exceptions.dart';
import 'package:e_learning/core/erros/network_exception_handler.dart';
import 'package:e_learning/features/admin_panel/add_courses/data/repo/admin_courses_repo.dart';
import 'package:e_learning/features/admin_panel/add_courses/presentation/logic/admin_courses_states.dart';
import 'package:e_learning/features/courses/data/model/courses.dart';

class AdminCoursesCubit extends Cubit<AdminCoursesState> {
  final AdminCoursesRepo _repo;

  AdminCoursesCubit(this._repo) : super(AdminCoursesInitial());

  // ── helper: current courses list من أي state ─────────────
  List<CourseModel> get _currentCourses {
    final s = state;
    if (s is AdminCoursesLoaded) return s.courses;
    if (s is AdminCoursesActionLoading) return s.courses;
    if (s is AdminCoursesActionSuccess) return s.courses;
    if (s is AdminCoursesActionError) return s.courses;
    return [];
  }

  // ── Fetch all ─────────────────────────────────────────────
  Future<void> fetchCourses() async {
    emit(AdminCoursesLoading());
    try {
      final courses = await _repo.fetchAllCourses();
      emit(AdminCoursesLoaded(courses));
    } on AppException catch (e) {
      emit(AdminCoursesError(e));
    } catch (e) {
      emit(AdminCoursesError(NetworkExceptionHandler.handle(e)));
    }
  }

  // ── Create course ─────────────────────────────────────────
  Future<void> createCourse({
    required String title,
    required String category,
    required String instructor,
    required String description,
    required String thumbnailUrl,
    required String duration,
    required String level,
    required double rating,
    required bool isFeatured,
  }) async {
    final prev = _currentCourses;
    emit(AdminCoursesActionLoading(prev));
    try {
      await _repo.createCourse(
        title: title,
        category: category,
        instructor: instructor,
        description: description,
        thumbnailUrl: thumbnailUrl,
        duration: duration,
        level: level,
        rating: rating,
        isFeatured: isFeatured,
      );
      // بعد الـ create نعمل fetch عشان نجيب الـ id الجديد من الـ DB
      final updated = await _repo.fetchAllCourses();
      emit(AdminCoursesActionSuccess(
          courses: updated, message: 'Course created!'));
    } on AppException catch (e) {
      emit(AdminCoursesActionError(courses: prev, exception: e));
    } catch (e) {
      emit(AdminCoursesActionError(
          courses: prev, exception: NetworkExceptionHandler.handle(e)));
    }
  }

  // ── Update course ─────────────────────────────────────────
  Future<void> updateCourse({
    required String courseId,
    required String title,
    required String category,
    required String instructor,
    required String description,
    required String thumbnailUrl,
    required String duration,
    required String level,
    required double rating,
    required bool isFeatured,
  }) async {
    final prev = _currentCourses;
    emit(AdminCoursesActionLoading(prev));
    try {
      await _repo.updateCourse(
        courseId: courseId,
        title: title,
        category: category,
        instructor: instructor,
        description: description,
        thumbnailUrl: thumbnailUrl,
        duration: duration,
        level: level,
        rating: rating,
        isFeatured: isFeatured,
      );
      final updated = await _repo.fetchAllCourses();
      emit(AdminCoursesActionSuccess(
          courses: updated, message: 'Course updated!'));
    } on AppException catch (e) {
      emit(AdminCoursesActionError(courses: prev, exception: e));
    } catch (e) {
      emit(AdminCoursesActionError(
          courses: prev, exception: NetworkExceptionHandler.handle(e)));
    }
  }

  // ── Delete course (optimistic) ────────────────────────────
  Future<void> deleteCourse(String courseId) async {
    final prev = _currentCourses;
    // نشيله فوراً من الـ UI
    final optimistic = prev.where((c) => c.id != courseId).toList();
    emit(AdminCoursesActionLoading(optimistic));
    try {
      await _repo.deleteCourse(courseId);
      emit(AdminCoursesActionSuccess(
          courses: optimistic, message: 'Course deleted!'));
    } on AppException catch (e) {
      // rollback
      emit(AdminCoursesActionError(courses: prev, exception: e));
    } catch (e) {
      emit(AdminCoursesActionError(
          courses: prev, exception: NetworkExceptionHandler.handle(e)));
    }
  }

  // ── Add video ─────────────────────────────────────────────
  Future<void> addVideo({
    required String courseId,
    required String title,
    required String duration,
    required String videoUrl,
    required bool isLocked,
  }) async {
    final prev = _currentCourses;
    emit(AdminCoursesActionLoading(prev));
    try {
      await _repo.addVideo(
        courseId: courseId,
        title: title,
        duration: duration,
        videoUrl: videoUrl,
        isLocked: isLocked,
      );
      final updated = await _repo.fetchAllCourses();
      emit(AdminCoursesActionSuccess(
          courses: updated, message: 'Video added!'));
    } on AppException catch (e) {
      emit(AdminCoursesActionError(courses: prev, exception: e));
    } catch (e) {
      emit(AdminCoursesActionError(
          courses: prev, exception: NetworkExceptionHandler.handle(e)));
    }
  }

  // ── Delete video (optimistic) ─────────────────────────────
  Future<void> deleteVideo({
    required String videoId,
    required String courseId,
  }) async {
    final prev = _currentCourses;
    // نشيل الفيديو من الـ course في الـ UI فوراً
    final optimistic = prev.map((c) {
      if (c.id != courseId) return c;
      return c.copyWith(
          videos: c.videos.where((v) => v.id != videoId).toList());
    }).toList();
    emit(AdminCoursesActionLoading(optimistic));
    try {
      await _repo.deleteVideo(videoId, courseId);
      emit(AdminCoursesActionSuccess(
          courses: optimistic, message: 'Video deleted!'));
    } on AppException catch (e) {
      // rollback
      emit(AdminCoursesActionError(courses: prev, exception: e));
    } catch (e) {
      emit(AdminCoursesActionError(
          courses: prev, exception: NetworkExceptionHandler.handle(e)));
    }
  }
}
