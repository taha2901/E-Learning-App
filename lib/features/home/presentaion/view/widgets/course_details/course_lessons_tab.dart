import 'package:e_learning/core/constants/app_constants.dart';
import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/features/courses/data/model/courses.dart';
import 'package:flutter/material.dart';

class CourseLessonsTab extends StatelessWidget {
  final CourseModel course;
  final bool isEnrolled;
  final Set<String> watchedVideoIds;
  final ValueChanged<VideoModel> onVideoTap;

  const CourseLessonsTab({
    super.key,
    required this.course,
    required this.isEnrolled,
    required this.watchedVideoIds,
    required this.onVideoTap,
  });

  @override
  Widget build(BuildContext context) {
    if (course.videos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.video_library_outlined,
                  size: 64, color: AppColors.textHint),
              SizedBox(height: 16),
              Text('No lessons available yet',
                  style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${course.videos.length} Lessons  •  ${course.duration}',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 16),
          ...course.videos.map(
            (video) => _LessonItem(
              video: video,
              isEnrolled: isEnrolled,
              isWatched: watchedVideoIds.contains(video.id),
              onTap: () {
                if (!video.isLocked || isEnrolled) onVideoTap(video);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonItem extends StatelessWidget {
  final VideoModel video;
  final bool isEnrolled;
  final bool isWatched;
  final VoidCallback onTap;

  const _LessonItem({
    required this.video,
    required this.isEnrolled,
    required this.isWatched,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final locked = video.isLocked && !isEnrolled;
    return GestureDetector(
      onTap: locked ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
          border: Border.all(
            color: isWatched
                ? AppColors.success.withOpacity(0.3)
                : AppColors.cardBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isWatched
                    ? AppColors.success.withOpacity(0.1)
                    : locked
                        ? AppColors.surfaceVariant
                        : AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isWatched
                    ? Icons.check_rounded
                    : locked
                        ? Icons.lock_outline_rounded
                        : Icons.play_arrow_rounded,
                color: isWatched
                    ? AppColors.success
                    : locked
                        ? AppColors.textHint
                        : AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    style: AppTextStyles.h3.copyWith(
                        color: locked
                            ? AppColors.textHint
                            : AppColors.textPrimary),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.schedule_outlined,
                          size: 13, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text(video.duration,
                          style: AppTextStyles.caption),
                    ],
                  ),
                ],
              ),
            ),
            if (isWatched)
              Text(
                'Watched ✓',
                style: AppTextStyles.caption.copyWith(
                    color: AppColors.success, fontWeight: FontWeight.w600),
              ),
          ],
        ),
      ),
    );
  }
}