import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/features/courses/data/model/courses.dart';
import 'package:flutter/material.dart';

class MyCourseDetailsLessonItem extends StatelessWidget {
  final VideoModel video;
  final int index;
  final bool isWatched;
  final bool isCurrent;
  final bool hasQuiz;
  final VoidCallback onTap;
  final VoidCallback? onQuizTap;

  const MyCourseDetailsLessonItem({
    super.key,
    required this.video,
    required this.index,
    required this.isWatched,
    required this.isCurrent,
    required this.hasQuiz,
    required this.onTap,
    this.onQuizTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isCurrent
              ? AppColors.primary.withOpacity(0.06)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isWatched
                ? AppColors.success.withOpacity(0.4)
                : isCurrent
                    ? AppColors.primary.withOpacity(0.4)
                    : AppColors.cardBorder,
            width: isCurrent ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Index / state icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isWatched
                    ? AppColors.success.withOpacity(0.1)
                    : isCurrent
                        ? AppColors.primary.withOpacity(0.1)
                        : AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: isWatched
                  ? const Icon(Icons.check_rounded,
                      color: AppColors.success, size: 22)
                  : isCurrent
                      ? const Icon(Icons.play_arrow_rounded,
                          color: AppColors.primary, size: 22)
                      : Center(
                          child: Text(
                            '$index',
                            style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
            ),
            const SizedBox(width: 14),

            // Title + duration + quiz badge
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    style: AppTextStyles.h3.copyWith(
                      color: isWatched
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.schedule_outlined,
                          size: 12, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text(video.duration, style: AppTextStyles.caption),
                      if (hasQuiz) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: onQuizTap,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                  color: AppColors.warning.withOpacity(0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.quiz_rounded,
                                    size: 10,
                                    color: AppColors.warning.withOpacity(0.9)),
                                const SizedBox(width: 3),
                                Text(
                                  'Quiz',
                                  style: AppTextStyles.caption.copyWith(
                                      fontSize: 10,
                                      color: AppColors.warning,
                                      fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Status badge / icon
            if (isWatched)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  'Done',
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.success, fontWeight: FontWeight.w700),
                ),
              )
            else if (isCurrent)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  'Next',
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w700),
                ),
              )
            else
              const Icon(Icons.play_circle_outline_rounded,
                  color: AppColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}