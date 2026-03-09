// screens/admin_courses_screen.dart

import 'package:e_learning/core/erros/app_error_widget.dart';
import 'package:e_learning/core/erros/app_exceptions.dart';
import 'package:e_learning/core/erros/network_exception_handler.dart';
import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/features/admin_panel/add_courses/data/repo/admin_courses_repo.dart';
import 'package:e_learning/features/admin_panel/add_courses/presentation/view/create_edit_course_screen.dart';
import 'package:e_learning/features/admin_panel/add_courses/presentation/view/manage_videos_screen.dart';
import 'package:e_learning/features/admin_panel/add_courses/presentation/view/widgets/admin_back_button.dart';
import 'package:e_learning/features/admin_panel/add_courses/presentation/view/widgets/course_admin_card.dart';
import 'package:e_learning/features/courses/data/model/courses.dart';
import 'package:flutter/material.dart';

class AdminCoursesScreen extends StatefulWidget {
  const AdminCoursesScreen({super.key});

  @override
  State<AdminCoursesScreen> createState() => _AdminCoursesScreenState();
}

class _AdminCoursesScreenState extends State<AdminCoursesScreen> {
  final _repo = AdminCoursesRepo();
  List<CourseModel> _courses = [];
  bool _loading = true;
  AppException? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final courses = await _repo.fetchAllCourses();
      if (mounted) setState(() { _courses = courses; _loading = false; });
    } on AppException catch (e) {
      if (mounted) setState(() { _loadError = e; _loading = false; });
    } catch (e) {
      if (mounted) setState(() {
        _loadError = NetworkExceptionHandler.handle(e);
        _loading = false;
      });
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Navigation helpers ───────────────────────────────────

  Future<void> _goToCreateCourse() async {
    await Navigator.push(context, MaterialPageRoute(
      builder: (_) => CreateEditCourseScreen(repo: _repo),
    ));
    _load();
  }

  Future<void> _goToEditCourse(CourseModel course) async {
    await Navigator.push(context, MaterialPageRoute(
      builder: (_) => CreateEditCourseScreen(repo: _repo, course: course),
    ));
    _load();
  }

  Future<void> _goToManageVideos(CourseModel course) async {
    await Navigator.push(context, MaterialPageRoute(
      builder: (_) => ManageVideosScreen(course: course, repo: _repo),
    ));
    _load();
  }

  Future<void> _deleteCourse(CourseModel course) async {
    try {
      await _repo.deleteCourse(course.id);
      _load();
    } on AppException catch (e) {
      _showSnack(e.message, isError: true);
    }
  }

  // ── Build ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _AdminAppBar(
            courseCount: _courses.length,
            onAddTap: _goToCreateCourse,
          ),
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loadError != null && !_loading) {
      return SliverFillRemaining(
        child: AppErrorWidget(exception: _loadError!, onRetry: _load),
      );
    }
    if (_loading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_courses.isEmpty) {
      return const SliverFillRemaining(child: _EmptyCoursesState());
    }
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, i) => CourseAdminCard(
            course: _courses[i],
            onEdit: () => _goToEditCourse(_courses[i]),
            onManageVideos: () => _goToManageVideos(_courses[i]),
            onDelete: () => _deleteCourse(_courses[i]),
          ),
          childCount: _courses.length,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// App Bar
// ─────────────────────────────────────────────
class _AdminAppBar extends StatelessWidget {
  final int courseCount;
  final VoidCallback onAddTap;

  const _AdminAppBar({required this.courseCount, required this.onAddTap});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: const AdminBackButton(),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Course Manager', style: AppTextStyles.h2),
          Text(
            '$courseCount courses',
            style:
                AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: onAddTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                children: [
                  const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    'New Course',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────
class _EmptyCoursesState extends StatelessWidget {
  const _EmptyCoursesState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.school_outlined,
                size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          Text('No courses yet', style: AppTextStyles.h2),
          const SizedBox(height: 8),
          Text(
            'Tap "New Course" to get started',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}