import 'package:flutter/material.dart';
import 'package:e_learning/features/courses/data/repo/course_repo.dart';
import 'package:e_learning/features/courses/data/model/courses.dart';

class WishlistNotifier extends ChangeNotifier {
  static final WishlistNotifier _instance = WishlistNotifier._();
  factory WishlistNotifier() => _instance;
  WishlistNotifier._();

  final Set<String> _savedIds = {};
  List<CourseModel> _savedCourses = [];
  bool _loaded = false;

  Set<String> get savedIds => _savedIds;
  List<CourseModel> get savedCourses => _savedCourses;
  bool isSaved(String courseId) => _savedIds.contains(courseId);

  Future<void> load(String userId) async {
    if (_loaded) return;
    try {
      final courses = await CoursesRepo().fetchWishlist(userId);
      _savedCourses = courses;
      _savedIds.addAll(courses.map((c) => c.id));
      _loaded = true;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> toggle(String userId, CourseModel course) async {
    if (_savedIds.contains(course.id)) {
      // ── Remove ───────────────────────────────────────────────
      _savedIds.remove(course.id);
      _savedCourses.removeWhere((c) => c.id == course.id);
      notifyListeners();
      await CoursesRepo().removeFromWishlist(userId, course.id);
    } else {
      // ── Add ──────────────────────────────────────────────────
      _savedIds.add(course.id);
      _savedCourses.insert(0, course);
      notifyListeners();
      await CoursesRepo().addToWishlist(userId, course.id);
    }
  }

  void reset() {
    _savedIds.clear();
    _savedCourses.clear();
    _loaded = false;
  }
}