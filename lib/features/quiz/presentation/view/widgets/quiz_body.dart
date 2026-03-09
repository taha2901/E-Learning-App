import 'package:e_learning/core/erros/app_error_widget.dart';
import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/features/quiz/presentation/logic/quiz_cubit.dart';
import 'package:e_learning/features/quiz/presentation/logic/quiz_states.dart';
import 'package:e_learning/features/quiz/presentation/view/quiz_result_screen.dart';
import 'package:e_learning/features/quiz/presentation/view/widgets/option_tile.dart';
import 'package:e_learning/features/quiz/presentation/view/widgets/quiz_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'question_widgets.dart';

class QuizBody extends StatelessWidget {
  final VoidCallback? onComplete;
  const QuizBody({super.key, this.onComplete});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<QuizCubit, QuizState>(
      listener: _onStateChange,
      builder: _buildState,
    );
  }

  // ── Listener ─────────────────────────────────────────────

  void _onStateChange(BuildContext context, QuizState state) {
    if (state is QuizFinished) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: context.read<QuizCubit>(),
            child: QuizResultScreen(
              onContinue: () {
                Navigator.of(context).popUntil((route) {
                  return route.isFirst ||
                      route.settings.name != null ||
                      !route.settings.name.toString().contains('quiz');
                });
                try {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                } catch (_) {}
                onComplete?.call();
              },
            ),
          ),
        ),
      );
    }

    // Non-fatal error during quiz — show snackbar to avoid blocking the flow
    if (state is QuizError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.exception.message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  // ── Builder ──────────────────────────────────────────────

  Widget _buildState(BuildContext context, QuizState state) {
    // Fatal error before quiz starts — show full-screen error
    if (state is QuizError) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: AppErrorWidget(
          exception: state.exception,
          onRetry: () => Navigator.pop(context),
        ),
      );
    }

    if (state is! QuizInProgress) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return _QuizInProgressView(state: state);
  }
}

// ─────────────────────────────────────────────
// Quiz In-Progress View
// ─────────────────────────────────────────────
class _QuizInProgressView extends StatelessWidget {
  final QuizInProgress state;
  const _QuizInProgressView({required this.state});

  @override
  Widget build(BuildContext context) {
    final q = state.quiz.questions[state.currentIndex];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            QuizAppBar(state: state),
            QuestionBadge(
              current: state.currentIndex + 1,
              total: state.quiz.questions.length,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    QuestionCard(question: q.question),
                    const SizedBox(height: 20),
                    ...['a', 'b', 'c', 'd'].map(
                      (letter) => OptionTile(
                        letter: letter,
                        text: q.optionText(letter),
                        selected: state.selectedAnswer == letter,
                        correct:
                            state.answered && letter == q.correctAnswer,
                        wrong: state.answered &&
                            state.selectedAnswer == letter &&
                            letter != q.correctAnswer,
                        onTap: () =>
                            context.read<QuizCubit>().selectAnswer(letter),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}