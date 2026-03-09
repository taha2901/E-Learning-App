import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/features/admin_panel/add_courses/presentation/logic/admin_courses_cubit.dart';
import 'package:e_learning/features/admin_panel/add_courses/presentation/logic/admin_courses_states.dart';
import 'package:e_learning/features/admin_panel/add_courses/presentation/view/widgets/add_video_sheet.dart';
import 'package:e_learning/features/admin_panel/add_courses/presentation/view/widgets/admin_back_button.dart';
import 'package:e_learning/features/admin_panel/add_courses/presentation/view/widgets/video_list_tile.dart';
import 'package:e_learning/features/courses/data/model/courses.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ManageVideosScreen extends StatelessWidget {
  final CourseModel course;

  const ManageVideosScreen({super.key, required this.course});

  Future<void> _addVideo(BuildContext context) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const AddVideoSheet(),
    );

    if (result == null || !context.mounted) return;

    context.read<AdminCoursesCubit>().addVideo(
          courseId: course.id,
          title: result['title'],
          duration: result['duration'],
          videoUrl: result['video_url'],
          isLocked: result['is_locked'],
        );
  }

  void _confirmDelete(BuildContext context, VideoModel video) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Video?', style: AppTextStyles.h2),
        content: Text('Delete "${video.title}"?',
            style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AdminCoursesCubit>().deleteVideo(
                    videoId: video.id,
                    courseId: course.id,
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminCoursesCubit, AdminCoursesState>(
      listener: (context, state) {
        if (state is AdminCoursesActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ));
        }
        if (state is AdminCoursesActionError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.exception.message),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ));
        }
      },
      builder: (context, state) {
        final isLoading = state is AdminCoursesActionLoading;

        // بنجيب الـ videos للـ course ده من الـ state
        final courses = switch (state) {
          AdminCoursesLoaded s => s.courses,
          AdminCoursesActionLoading s => s.courses,
          AdminCoursesActionSuccess s => s.courses,
          AdminCoursesActionError s => s.courses,
          _ => <CourseModel>[],
        };
        final currentCourse = courses.firstWhere(
          (c) => c.id == course.id,
          orElse: () => course,
        );
        final videos = currentCourse.videos;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: const AdminBackButton(),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Videos', style: AppTextStyles.h2),
                Text(
                  course.title,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: isLoading ? null : () => _addVideo(context),
                  child: _AddButton(isAdding: isLoading),
                ),
              ),
            ],
          ),
          body: videos.isEmpty
              ? const _EmptyVideosState()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: videos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => VideoListTile(
                    video: videos[i],
                    onDelete: () => _confirmDelete(context, videos[i]),
                  ),
                ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
class _AddButton extends StatelessWidget {
  final bool isAdding;
  const _AddButton({required this.isAdding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isAdding
            ? AppColors.primary.withOpacity(0.5)
            : AppColors.primary,
        borderRadius: BorderRadius.circular(100),
      ),
      child: isAdding
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2),
            )
          : Row(children: [
              const Icon(Icons.add_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 4),
              Text('Add',
                  style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ]),
    );
  }
}

// ─────────────────────────────────────────────
class _EmptyVideosState extends StatelessWidget {
  const _EmptyVideosState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.video_library_outlined,
              size: 56, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text('No videos yet', style: AppTextStyles.h2),
          const SizedBox(height: 8),
          Text('Tap "Add" to add lessons',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}