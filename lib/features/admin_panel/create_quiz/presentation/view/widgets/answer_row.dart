import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:flutter/material.dart';

class AnswerRow extends StatelessWidget {
  final String letter;
  final String text;
  final bool isCorrect;

  const AnswerRow({
    super.key,
    required this.letter,
    required this.text,
    required this.isCorrect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: isCorrect ? AppColors.success : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                letter.toUpperCase(),
                style: AppTextStyles.caption.copyWith(
                  color: isCorrect ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: isCorrect ? AppColors.success : AppColors.textPrimary,
              ),
            ),
          ),
          if (isCorrect)
            const Icon(Icons.check_rounded, color: AppColors.success, size: 16),
        ],
      ),
    );
  }
}