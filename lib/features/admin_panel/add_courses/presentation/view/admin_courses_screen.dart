import 'package:e_learning/core/erros/app_error_widget.dart';
import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/features/admin_panel/add_courses/data/repo/admin_courses_repo.dart';
import 'package:e_learning/features/admin_panel/add_courses/presentation/logic/admin_courses_cubit.dart';
import 'package:e_learning/features/admin_panel/add_courses/presentation/logic/admin_courses_states.dart';
import 'package:e_learning/features/admin_panel/add_courses/presentation/view/create_edit_course_screen.dart';
import 'package:e_learning/features/admin_panel/add_courses/presentation/view/manage_videos_screen.dart';
import 'package:e_learning/features/admin_panel/add_courses/presentation/view/widgets/admin_back_button.dart';
import 'package:e_learning/features/admin_panel/add_courses/presentation/view/widgets/course_admin_card.dart';
import 'package:e_learning/features/courses/data/model/courses.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AdminCoursesScreen extends StatelessWidget {
  const AdminCoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminCoursesCubit(AdminCoursesRepo())..fetchCourses(),
      child: const _AdminCoursesBody(),
    );
  }
}

// ─────────────────────────────────────────────
class _AdminCoursesBody extends StatelessWidget {
  const _AdminCoursesBody();

  void _showSnack(BuildContext context, String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<void> _goToCreateCourse(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<AdminCoursesCubit>(),
          child: const CreateEditCourseScreen(),
        ),
      ),
    );
  }

  Future<void> _goToEditCourse(BuildContext context, CourseModel course) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<AdminCoursesCubit>(),
          child: CreateEditCourseScreen(course: course),
        ),
      ),
    );
  }

  Future<void> _goToManageVideos(
      BuildContext context, CourseModel course) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<AdminCoursesCubit>(),
          child: ManageVideosScreen(course: course),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminCoursesCubit, AdminCoursesState>(
      listener: (context, state) {
        if (state is AdminCoursesActionSuccess) {
          _showSnack(context, state.message);
        }
        if (state is AdminCoursesActionError) {
          _showSnack(context, state.exception.message, isError: true);
        }
      },
      builder: (context, state) {
        final courses = switch (state) {
          AdminCoursesLoaded s => s.courses,
          AdminCoursesActionLoading s => s.courses,
          AdminCoursesActionSuccess s => s.courses,
          AdminCoursesActionError s => s.courses,
          _ => <CourseModel>[],
        };

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              _AdminAppBar(
                courseCount: courses.length,
                onAddTap: () => _goToCreateCourse(context),
              ),
              _buildContent(context, state, courses),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(
      BuildContext context, AdminCoursesState state, List<CourseModel> courses) {
    // Error state — أول تحميل فشل
    if (state is AdminCoursesError) {
      return SliverFillRemaining(
        child: AppErrorWidget(
          exception: state.exception,
          onRetry: () => context.read<AdminCoursesCubit>().fetchCourses(),
        ),
      );
    }

    // Loading — أول تحميل
    if (state is AdminCoursesLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Empty
    if (courses.isEmpty) {
      return const SliverFillRemaining(child: _EmptyCoursesState());
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, i) {
            final course = courses[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CourseAdminCard(
                course: course,
                onEdit: () => _goToEditCourse(context, course),
                onManageVideos: () => _goToManageVideos(context, course),
                onDelete: () =>
                    context.read<AdminCoursesCubit>().deleteCourse(course.id),
              ),
            );
          },
          childCount: courses.length,
        ),
      ),
    );
  }
}

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
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: onAddTap,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(children: [
                const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 4),
                Text('New Course',
                    style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ),
      ],
    );
  }
}

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
          Text('Tap "New Course" to get started',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}