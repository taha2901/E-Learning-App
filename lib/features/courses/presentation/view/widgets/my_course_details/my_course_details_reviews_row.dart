import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:flutter/material.dart';

class MyCourseDetailsReviewsRow extends StatelessWidget {
  final double currentRating;
  final VoidCallback onTap;

  const MyCourseDetailsReviewsRow({
    super.key,
    required this.currentRating,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.star_rounded,
                color: Color(0xFFF59E0B), size: 22),
            const SizedBox(width: 10),
            Text(
              currentRating.toStringAsFixed(1),
              style: AppTextStyles.h3.copyWith(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 8),
            Text('Reviews & Ratings', style: AppTextStyles.h3),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}