import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/features/admin_panel/create_quiz/presentation/view/widgets/answer_row.dart';
import 'package:e_learning/features/quiz/data/model/quiz_model.dart';
import 'package:flutter/material.dart';

class QuestionCardOfCreation extends StatelessWidget {
  final QuizQuestion question;
  final int index;
  final VoidCallback? onDelete;

  const QuestionCardOfCreation({
    super.key,
    required this.question,
    required this.index,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isTemp = question.id.startsWith('temp_');

    return AnimatedOpacity(
      opacity: isTemp ? 0.6 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isTemp
                ? AppColors.primary.withOpacity(0.3)
                : AppColors.cardBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isTemp),
            const SizedBox(height: 10),
            Text(question.question, style: AppTextStyles.h3),
            const SizedBox(height: 12),
            ...['a', 'b', 'c', 'd'].map(
              (l) => AnswerRow(
                letter: l,
                text: question.optionText(l),
                isCorrect: l == question.correctAnswer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isTemp) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            'Q${index + 1}',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (isTemp) ...[
          const SizedBox(width: 8),
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ],
        const Spacer(),
        if (!isTemp)
          GestureDetector(
            onTap: onDelete,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.error,
                size: 16,
              ),
            ),
          ),
      ],
    );
  }
}