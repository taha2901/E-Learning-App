// widgets/saved_course_card.dart

import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/features/courses/data/model/courses.dart';
import 'package:flutter/material.dart';

class SavedCourseCard extends StatelessWidget {
  final CourseModel course;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const SavedCourseCard({
    super.key,
    required this.course,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _CourseThumbnail(url: course.thumbnailUrl),
            const SizedBox(width: 14),
            Expanded(child: _CourseInfo(course: course)),
            _RemoveButton(onRemove: onRemove),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Thumbnail
// ─────────────────────────────────────────────
class _CourseThumbnail extends StatelessWidget {
  final String url;
  const _CourseThumbnail({required this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        width: 88,
        height: 88,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 88,
          height: 88,
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
          child: const Icon(Icons.school_rounded,
              color: Colors.white, size: 32),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Course Info  (category + title + rating + duration)
// ─────────────────────────────────────────────
class _CourseInfo extends StatelessWidget {
  final CourseModel course;
  const _CourseInfo({required this.course});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          course.category.toUpperCase(),
          style: AppTextStyles.caption.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          course.title,
          style: AppTextStyles.h3,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        _CourseMetaRow(rating: course.rating, duration: course.duration),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Rating + Duration row
// ─────────────────────────────────────────────
class _CourseMetaRow extends StatelessWidget {
  final double rating;
  final String duration;

  const _CourseMetaRow({required this.rating, required this.duration});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.star_rounded,
            size: 13, color: Color(0xFFFBBF24)),
        const SizedBox(width: 3),
        Text(
          '$rating',
          style: AppTextStyles.caption
              .copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 10),
        const Icon(Icons.schedule_outlined,
            size: 13, color: AppColors.textHint),
        const SizedBox(width: 3),
        Text(duration, style: AppTextStyles.caption),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Remove Button
// ─────────────────────────────────────────────
class _RemoveButton extends StatelessWidget {
  final VoidCallback onRemove;
  const _RemoveButton({required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onRemove,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.08),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.bookmark_remove_rounded,
            color: AppColors.error, size: 18),
      ),
    );
  }
}