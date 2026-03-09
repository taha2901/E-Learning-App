import 'package:e_learning/core/constants/app_constants.dart';
import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/features/courses/data/model/courses.dart';
import 'package:flutter/material.dart';

class CourseInfoSection extends StatelessWidget {
  final CourseModel course;
  final double currentRating;

  const CourseInfoSection({
    super.key,
    required this.course,
    required this.currentRating,
  });

  String _fmt(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : n.toString();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            course.category.toUpperCase(),
            style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8),
          ),
          const SizedBox(height: 8),
          Text(course.title, style: AppTextStyles.h1),
          const SizedBox(height: 12),
          Row(
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(
                    'https://picsum.photos/seed/instructor/100/100'),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Instructor', style: AppTextStyles.caption),
                  Text(
                    course.instructor,
                    style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: Icons.star_rounded,
                label: currentRating.toStringAsFixed(1),
                color: const Color(0xFFFBBF24),
              ),
              _InfoChip(
                icon: Icons.people_outline_rounded,
                label: '${_fmt(course.studentsCount)} students',
              ),
              _InfoChip(
                icon: Icons.play_lesson_outlined,
                label:
                    '${course.videos.isNotEmpty ? course.videos.length : course.lessonsCount} lessons',
              ),
              _InfoChip(
                  icon: Icons.schedule_outlined, label: course.duration),
              _InfoChip(
                  icon: Icons.signal_cellular_alt_rounded,
                  label: course.level),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? AppColors.textHint),
          const SizedBox(width: 5),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}