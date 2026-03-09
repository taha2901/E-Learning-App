// widgets/result_score_circle.dart

import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/features/quiz/presentation/logic/quiz_states.dart';
import 'package:flutter/material.dart';

class ResultScoreCircle extends StatelessWidget {
  final QuizFinished state;
  final Color color;
  final Animation<double> scaleAnim;
  final Animation<double> fadeAnim;

  const ResultScoreCircle({
    super.key,
    required this.state,
    required this.color,
    required this.scaleAnim,
    required this.fadeAnim,
  });

  @override
  Widget build(BuildContext context) {
    final emoji = state.passed ? '🎉' : '😔';

    return FadeTransition(
      opacity: fadeAnim,
      child: ScaleTransition(
        scale: scaleAnim,
        child: Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.15),
                color.withOpacity(0.05),
              ],
            ),
            border: Border.all(color: color.withOpacity(0.3), width: 3),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 36)),
              Text(
                '${state.percentage}%',
                style: AppTextStyles.displayMedium.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}