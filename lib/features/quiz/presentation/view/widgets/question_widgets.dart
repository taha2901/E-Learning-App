// ─────────────────────────────────────────────
// question_widgets.dart
// Contains: QuestionCard, QuestionBadge
// OptionTile lives in option_tile.dart — import from there
// ─────────────────────────────────────────────

import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
// Question Card  (the question text box)
// ─────────────────────────────────────────────
class QuestionCard extends StatelessWidget {
  final String question;
  const QuestionCard({super.key, required this.question});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        question,
        style: AppTextStyles.h2.copyWith(height: 1.5),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Question Badge  ("Question 2 of 10" pill)
// ─────────────────────────────────────────────
class QuestionBadge extends StatelessWidget {
  final int current;
  final int total;

  const QuestionBadge({
    super.key,
    required this.current,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              'Question $current of $total',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
