// screens/quiz_result_screen.dart

import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/features/quiz/presentation/logic/quiz_cubit.dart';
import 'package:e_learning/features/quiz/presentation/logic/quiz_states.dart';
import 'package:e_learning/features/quiz/presentation/view/widgets/result_score_circle.dart';
import 'package:e_learning/features/quiz/presentation/view/widgets/result_stats_row.dart';
import 'package:e_learning/features/quiz/presentation/view/widgets/review_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class QuizResultScreen extends StatefulWidget {
  final VoidCallback onContinue;
  const QuizResultScreen({super.key, required this.onContinue});

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;
  bool _showReview = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fadeAnim  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QuizCubit, QuizState>(
      builder: (context, state) {
        if (state is! QuizFinished) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return PopScope(
          canPop: false,
          onPopInvoked: (didPop) {
            if (!didPop) widget.onContinue();
          },
          child: Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: _showReview
                  ? ReviewSection(
                      quiz: state.quiz,
                      answers: state.answers,
                      onBack: () => setState(() => _showReview = false),
                    )
                  : _ResultSummary(
                      state: state,
                      scaleAnim: _scaleAnim,
                      fadeAnim: _fadeAnim,
                      onReview: () => setState(() => _showReview = true),
                      onContinue: widget.onContinue,
                    ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Result Summary  (score circle + stats + buttons)
// ─────────────────────────────────────────────
class _ResultSummary extends StatelessWidget {
  final QuizFinished state;
  final Animation<double> scaleAnim;
  final Animation<double> fadeAnim;
  final VoidCallback onReview;
  final VoidCallback onContinue;

  const _ResultSummary({
    required this.state,
    required this.scaleAnim,
    required this.fadeAnim,
    required this.onReview,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final color   = state.passed ? AppColors.success : AppColors.error;
    final message = state.passed ? 'Great job!' : 'Keep practicing!';

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 32),
            ResultScoreCircle(
              state: state,
              color: color,
              scaleAnim: scaleAnim,
              fadeAnim: fadeAnim,
            ),
            const SizedBox(height: 24),
            FadeTransition(
              opacity: fadeAnim,
              child: _ResultMessage(
                state: state,
                color: color,
                message: message,
              ),
            ),
            const SizedBox(height: 32),
            FadeTransition(
              opacity: fadeAnim,
              child: ResultStatsRow(state: state),
            ),
            const SizedBox(height: 32),
            FadeTransition(
              opacity: fadeAnim,
              child: _ResultButtons(
                state: state,
                onReview: onReview,
                onContinue: onContinue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultMessage extends StatelessWidget {
  final QuizFinished state;
  final Color color;
  final String message;

  const _ResultMessage({
    required this.state,
    required this.color,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(message, style: AppTextStyles.h1.copyWith(color: color)),
        const SizedBox(height: 8),
        Text(
          state.passed
              ? 'You passed with ${state.score}/${state.total} correct'
              : 'You got ${state.score}/${state.total}. Need ${state.quiz.passScore}% to pass',
          style: AppTextStyles.bodyMedium
              .copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ResultButtons extends StatelessWidget {
  final QuizFinished state;
  final VoidCallback onReview;
  final VoidCallback onContinue;

  const _ResultButtons({
    required this.state,
    required this.onReview,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        OutlinedButton.icon(
          onPressed: onReview,
          icon: const Icon(Icons.list_alt_rounded),
          label: const Text('Review Answers'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        ),
        if (!state.passed) ...[
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => context.read<QuizCubit>().retryQuiz(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: onContinue,
          icon: const Icon(Icons.arrow_forward_rounded),
          label: Text(state.passed ? 'Continue Learning' : 'Continue Anyway'),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                state.passed ? AppColors.primary : AppColors.textSecondary,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }
}