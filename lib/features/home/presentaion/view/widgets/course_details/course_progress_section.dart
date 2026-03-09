import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:flutter/material.dart';

class CourseProgressSection extends StatelessWidget {
  final double progress;
  final int watched;
  final int total;

  const CourseProgressSection({
    super.key,
    required this.progress,
    required this.watched,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).toInt();
    final done = watched >= total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: done
            ? AppColors.success.withOpacity(0.08)
            : AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                done ? Icons.check_circle_rounded : Icons.play_lesson_outlined,
                color: done ? AppColors.success : AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                done
                    ? 'Course Completed! 🎉'
                    : '$watched of $total lessons watched',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: done ? AppColors.success : AppColors.primary,
                ),
              ),
              const Spacer(),
              Text(
                '$pct%',
                style: AppTextStyles.h3.copyWith(
                    color: done ? AppColors.success : AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white,
              valueColor: AlwaysStoppedAnimation<Color>(
                  done ? AppColors.success : AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}