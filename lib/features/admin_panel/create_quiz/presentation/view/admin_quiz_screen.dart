// ─────────────────────────────────────────────
// admin_quiz_screen.dart
// ─────────────────────────────────────────────

import 'package:e_learning/core/erros/app_error_widget.dart';
import 'package:e_learning/core/erros/app_exceptions.dart';
import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/features/admin_panel/create_quiz/presentation/logic/admin_quiz_cubit.dart';
import 'package:e_learning/features/admin_panel/create_quiz/presentation/logic/admin_quiz_states.dart';
import 'package:e_learning/features/admin_panel/create_quiz/presentation/view/add_questions_screen.dart';
import 'package:e_learning/features/admin_panel/create_quiz/presentation/view/create_quiz_screen.dart';
import 'package:e_learning/features/admin_panel/create_quiz/presentation/view/widgets/quiz_admin_card.dart';
import 'package:e_learning/features/quiz/data/model/quiz_model.dart';
import 'package:e_learning/features/quiz/data/repo/quiz_repo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AdminQuizScreen extends StatelessWidget {
  const AdminQuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminQuizCubit(QuizRepo())..loadAllQuizzes(),
      child: const _AdminQuizBody(),
    );
  }
}

class _AdminQuizBody extends StatelessWidget {
  const _AdminQuizBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<AdminQuizCubit, AdminQuizState>(
        builder: (context, state) {
          if (state is AdminQuizError) {
            return CustomScrollView(
              slivers: [
                _buildAppBar(context, 0, context.read<AdminQuizCubit>()),
                SliverFillRemaining(
                  child: AppErrorWidget(
                    exception: state.exception,
                    onRetry: () =>
                        context.read<AdminQuizCubit>().loadAllQuizzes(),
                  ),
                ),
              ],
            );
          }

          final isLoading = state is AdminQuizLoading;
          final quizzes =
              state is AdminQuizLoaded ? state.quizzes : <QuizModel>[];

          return CustomScrollView(
            slivers: [
              _buildAppBar(
                  context, quizzes.length, context.read<AdminQuizCubit>()),
              if (isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (quizzes.isEmpty)
                const SliverFillRemaining(child: _EmptyQuizView())
              else
                _buildQuizList(context, quizzes),
            ],
          );
        },
      ),
    );
  }

  SliverPadding _buildQuizList(
      BuildContext context, List<QuizModel> quizzes) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (ctx, i) => QuizAdminCard(
            quiz: quizzes[i],
            onEdit: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: context.read<AdminQuizCubit>(),
                    child: AddQuestionsScreen(quiz: quizzes[i]),
                  ),
                ),
              );
              // Reload after returning from edit screen
              context.read<AdminQuizCubit>().loadAllQuizzes();
            },
            onDelete: () async {
              try {
                await context
                    .read<AdminQuizCubit>()
                    .deleteQuiz(quizzes[i].id);
              } on AppException catch (e) {
                if (ctx.mounted) _showErrorSnack(ctx, e.message);
              }
            },
          ),
          childCount: quizzes.length,
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(
      BuildContext context, int count, AdminQuizCubit cubit) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 16, color: AppColors.textPrimary),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quiz Manager', style: AppTextStyles.h2),
          Text('$count quizzes',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary)),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: cubit,
                    child: const CreateQuizScreen(),
                  ),
                ),
              );
              cubit.loadAllQuizzes();
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                children: [
                  const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    'New Quiz',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showErrorSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }
}

// ─────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────
class _EmptyQuizView extends StatelessWidget {
  const _EmptyQuizView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.quiz_outlined,
                size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          Text('No quizzes yet', style: AppTextStyles.h2),
          const SizedBox(height: 8),
          Text(
            'Tap "New Quiz" to create your first quiz',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
