// widgets/quiz_app_bar.dart

import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/features/quiz/presentation/logic/quiz_states.dart';
import 'package:flutter/material.dart';

class QuizAppBar extends StatelessWidget {
  final QuizInProgress state;
  const QuizAppBar({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final progress =
        (state.currentIndex + 1) / state.quiz.questions.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          _CloseButton(onTap: () => _showExitDialog(context)),
          const SizedBox(width: 16),
          Expanded(
            child: _ProgressColumn(
              title: state.quiz.title,
              progress: progress,
            ),
          ),
          const SizedBox(width: 16),
          _TimerCircle(secondsLeft: state.secondsLeft),
        ],
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Exit Quiz?', style: AppTextStyles.h2),
        content: Text('Your progress will be lost.',
            style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continue Quiz'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Exit',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: const Icon(Icons.close_rounded,
            size: 18, color: AppColors.textSecondary),
      ),
    );
  }
}

class _ProgressColumn extends StatelessWidget {
  final String title;
  final double progress;

  const _ProgressColumn({required this.title, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: AppTextStyles.h3,
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.cardBorder,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }
}

class _TimerCircle extends StatelessWidget {
  final int secondsLeft;
  const _TimerCircle({required this.secondsLeft});

  Color get _timerColor {
    if (secondsLeft > 10) return AppColors.success;
    if (secondsLeft > 5) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final color = _timerColor;
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: secondsLeft / 30,
            strokeWidth: 4,
            backgroundColor: AppColors.cardBorder,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          Text(
            '$secondsLeft',
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}