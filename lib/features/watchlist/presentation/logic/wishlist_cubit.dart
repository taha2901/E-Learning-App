import 'package:bloc/bloc.dart';
import 'package:e_learning/core/erros/app_exceptions.dart';
import 'package:e_learning/core/erros/network_exception_handler.dart';
import 'package:e_learning/features/courses/data/model/courses.dart';
import 'package:e_learning/features/courses/data/repo/course_repo.dart';
import 'package:e_learning/features/watchlist/presentation/logic/wishlist_states.dart';

class WishlistCubit extends Cubit<WishlistState> {
  final CoursesRepo _repo;
  final String userId;

  WishlistCubit(this._repo, {required this.userId}) : super(WishlistInitial());

  // ── Load wishlist ─────────────────────────────────────────────────────────
  Future<void> load() async {
    if (state is WishlistLoaded) return;
    emit(WishlistLoading());
    try {
      final courses = await _repo.fetchWishlist(userId);
      final ids = courses.map((c) => c.id).toSet();
      emit(WishlistLoaded(courses: courses, savedIds: ids));
    } on AppException catch (e) {
      emit(WishlistError(e.message));
    } catch (e) {
      emit(WishlistError(NetworkExceptionHandler.handle(e).message));
    }
  }

  // ── Force reload ──────────────────────────────────────────────────────────
  Future<void> reload() async {
    emit(WishlistLoading());
    try {
      final courses = await _repo.fetchWishlist(userId);
      final ids = courses.map((c) => c.id).toSet();
      emit(WishlistLoaded(courses: courses, savedIds: ids));
    } on AppException catch (e) {
      emit(WishlistError(e.message));
    } catch (e) {
      emit(WishlistError(NetworkExceptionHandler.handle(e).message));
    }
  }

  // ── Toggle save/unsave ────────────────────────────────────────────────────
  Future<void> toggle(CourseModel course) async {
    if (state is! WishlistLoaded) return;
    final s = state as WishlistLoaded;

    if (s.isSaved(course.id)) {
      // Optimistic remove
      final newIds = Set<String>.from(s.savedIds)..remove(course.id);
      final newCourses =
          s.courses.where((c) => c.id != course.id).toList();
      emit(s.copyWith(courses: newCourses, savedIds: newIds));

      try {
        await _repo.removeFromWishlist(userId, course.id);
      } on AppException {
        // ✅ Rollback
        emit(s);
      } catch (_) {
        emit(s);
      }
    } else {
      // Optimistic add
      final newIds = Set<String>.from(s.savedIds)..add(course.id);
      final newCourses = [course, ...s.courses];
      emit(s.copyWith(courses: newCourses, savedIds: newIds));

      try {
        await _repo.addToWishlist(userId, course.id);
      } on AppException {
        // ✅ Rollback
        emit(s);
      } catch (_) {
        emit(s);
      }
    }
  }

  // ── Check if saved (safe) ─────────────────────────────────────────────────
  bool isSaved(String courseId) {
    if (state is WishlistLoaded) {
      return (state as WishlistLoaded).isSaved(courseId);
    }
    return false;
  }

  // ── Get saved courses ─────────────────────────────────────────────────────
  List<CourseModel> get savedCourses {
    if (state is WishlistLoaded) return (state as WishlistLoaded).courses;
    return [];
  }

  // ── Reset (on logout) ─────────────────────────────────────────────────────
  void reset() => emit(WishlistInitial());
}