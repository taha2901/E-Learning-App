// widgets/review_section.dart

import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/features/quiz/data/model/quiz_model.dart';
import 'package:flutter/material.dart';

class ReviewSection extends StatelessWidget {
  final QuizModel quiz;
  final Map<int, String> answers;
  final VoidCallback onBack;

  const ReviewSection({
    super.key,
    required this.quiz,
    required this.answers,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ReviewHeader(onBack: onBack),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: quiz.questions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (_, i) => _ReviewQuestionCard(
              index: i,
              quiz: quiz,
              answers: answers,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReviewHeader extends StatelessWidget {
  final VoidCallback onBack;
  const _ReviewHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
            ),
          ),
          const SizedBox(width: 12),
          Text('Review Answers', style: AppTextStyles.h2),
        ],
      ),
    );
  }
}

class _ReviewQuestionCard extends StatelessWidget {
  final int index;
  final QuizModel quiz;
  final Map<int, String> answers;

  const _ReviewQuestionCard({
    required this.index,
    required this.quiz,
    required this.answers,
  });

  @override
  Widget build(BuildContext context) {
    final q          = quiz.questions[index];
    final userAnswer = answers[index];
    final correct    = userAnswer == q.correctAnswer;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: correct
              ? AppColors.success.withOpacity(0.3)
              : AppColors.error.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _QuestionBadge(index: index, correct: correct),
          const SizedBox(height: 10),
          Text(q.question, style: AppTextStyles.h3),
          const SizedBox(height: 12),
          if (!correct && userAnswer != null)
            ReviewAnswer(
              letter: userAnswer,
              text: q.optionText(userAnswer),
              isCorrect: false,
              label: 'Your answer',
            ),
          ReviewAnswer(
            letter: q.correctAnswer,
            text: q.optionText(q.correctAnswer),
            isCorrect: true,
            label: 'Correct answer',
          ),
          if (userAnswer == null)
            Text(
              '⏰ Time expired',
              style: AppTextStyles.caption.copyWith(color: AppColors.error),
            ),
        ],
      ),
    );
  }
}

class _QuestionBadge extends StatelessWidget {
  final int index;
  final bool correct;

  const _QuestionBadge({required this.index, required this.correct});

  @override
  Widget build(BuildContext context) {
    final color = correct ? AppColors.success : AppColors.error;

    return Row(
      children: [
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            'Q${index + 1}',
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
          color: color,
          size: 18,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Review Answer  (correct / wrong answer pill)
// ─────────────────────────────────────────────
class ReviewAnswer extends StatelessWidget {
  final String letter;
  final String text;
  final bool isCorrect;
  final String label;

  const ReviewAnswer({
    super.key,
    required this.letter,
    required this.text,
    required this.isCorrect,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCorrect ? AppColors.success : AppColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                letter.toUpperCase(),
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTextStyles.caption.copyWith(color: color)),
                Text(text, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}