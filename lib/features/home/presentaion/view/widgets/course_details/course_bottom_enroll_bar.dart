import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/core/widgets/custom_btn.dart';
import 'package:flutter/material.dart';

class CourseBottomEnrollBar extends StatelessWidget {
  final bool isEnrolled;
  final VoidCallback onEnroll;
  final VoidCallback onContinue;

  const CourseBottomEnrollBar({
    super.key,
    required this.isEnrolled,
    required this.onEnroll,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.cardBorder)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, -4))
        ],
      ),
      child: SafeArea(
        child: isEnrolled
            ? Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 24),
                  const SizedBox(width: 10),
                  Text('You are enrolled!',
                      style:
                          AppTextStyles.h3.copyWith(color: AppColors.success)),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: onContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child:
                        Text('Continue', style: AppTextStyles.labelLarge),
                  ),
                ],
              )
            : AppPrimaryButton(
                label: 'Enroll Now – Free', onTap: onEnroll),
      ),
    );
  }
}