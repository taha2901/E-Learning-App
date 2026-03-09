import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:flutter/material.dart';

class CourseReviewsRow extends StatelessWidget {
  final double currentRating;
  final VoidCallback onTap;

  const CourseReviewsRow({
    super.key,
    required this.currentRating,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.star_rounded,
                color: Color(0xFFF59E0B), size: 20),
            const SizedBox(width: 8),
            Text(
              currentRating.toStringAsFixed(1),
              style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 6),
            Text(
              '· Reviews & Ratings',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 13, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}