// widgets/result_stats_row.dart

import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/features/quiz/presentation/logic/quiz_states.dart';
import 'package:flutter/material.dart';

class ResultStatsRow extends StatelessWidget {
  final QuizFinished state;
  const ResultStatsRow({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          _ResultStat(
            icon: Icons.check_circle_outline_rounded,
            value: '${state.score}',
            label: 'Correct',
            color: AppColors.success,
          ),
          _ResultStat(
            icon: Icons.cancel_outlined,
            value: '${state.total - state.score}',
            label: 'Wrong',
            color: AppColors.error,
          ),
          _ResultStat(
            icon: Icons.emoji_events_outlined,
            value: '${state.quiz.passScore}%',
            label: 'Pass score',
            color: AppColors.warning,
          ),
        ],
      ),
    );
  }
}

class _ResultStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _ResultStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 6),
          Text(value, style: AppTextStyles.h2.copyWith(color: color)),
          Text(
            label,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}