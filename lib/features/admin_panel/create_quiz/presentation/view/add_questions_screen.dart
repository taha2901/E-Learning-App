// ─────────────────────────────────────────────
// add_questions_screen.dart
// ─────────────────────────────────────────────

import 'package:e_learning/core/erros/app_exceptions.dart';
import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/features/admin_panel/create_quiz/presentation/logic/admin_quiz_cubit.dart';
import 'package:e_learning/features/admin_panel/create_quiz/presentation/logic/admin_quiz_states.dart';
import 'package:e_learning/features/admin_panel/create_quiz/presentation/view/widgets/add_question_sheet.dart';
import 'package:e_learning/features/admin_panel/create_quiz/presentation/view/widgets/question_card.dart';
import 'package:e_learning/features/quiz/data/model/quiz_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddQuestionsScreen extends StatefulWidget {
  final QuizModel quiz;
  const AddQuestionsScreen({super.key, required this.quiz});

  @override
  State<AddQuestionsScreen> createState() => _AddQuestionsScreenState();
}

class _AddQuestionsScreenState extends State<AddQuestionsScreen> {
  late List<QuizQuestion> _questions;
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _questions = List.from(widget.quiz.questions);
  }

  // ── Add Question ──────────────────────────────────────────────────────────
  Future<void> _addQuestion() async {
    if (_isAdding) return;

    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const AddQuestionSheet(),
    );

    if (result == null || !mounted) return;

    // Optimistic update — show temp question immediately
    final tempQuestion = QuizQuestion(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      quizId: widget.quiz.id,
      question: result['question']!,
      optionA: result['a']!,
      optionB: result['b']!,
      optionC: result['c']!,
      optionD: result['d']!,
      correctAnswer: result['correct']!,
      orderIndex: _questions.length,
    );

    setState(() {
      _questions = [..._questions, tempQuestion];
      _isAdding = true;
    });

    try {
      await context.read<AdminQuizCubit>().addQuestion(
            quizId: widget.quiz.id,
            videoId: widget.quiz.videoId,
            question: result['question']!,
            optionA: result['a']!,
            optionB: result['b']!,
            optionC: result['c']!,
            optionD: result['d']!,
            correctAnswer: result['correct']!,
            orderIndex: _questions.length - 1,
          );
    } on AppException catch (e) {
      _rollbackTempQuestion();
      _showErrorSnack(e.message);
    } catch (e) {
      _rollbackTempQuestion();
      _showErrorSnack(e.toString());
    }

    if (mounted) setState(() => _isAdding = false);
  }

  // ── Delete Question ───────────────────────────────────────────────────────
  Future<void> _deleteQuestion(int index) async {
    final removed = _questions[index];
    setState(() => _questions = List.from(_questions)..removeAt(index));

    try {
      await context.read<AdminQuizCubit>().deleteQuestion(
            questionId: removed.id,
            videoId: widget.quiz.videoId,
          );
    } on AppException catch (e) {
      if (mounted) {
        setState(
            () => _questions = List.from(_questions)..insert(index, removed));
        _showErrorSnack(e.message);
      }
    }
  }

  void _rollbackTempQuestion() {
    if (mounted) {
      setState(() {
        _questions =
            _questions.where((q) => !q.id.startsWith('temp_')).toList();
      });
    }
  }

  void _showErrorSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return BlocListener<AdminQuizCubit, AdminQuizState>(
      listenWhen: (_, curr) => curr is AdminQuizSaved,
      listener: (_, state) {
        if (state is AdminQuizSaved) {
          setState(() => _questions = List.from(state.quiz.questions));
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(),
        body: _questions.isEmpty
            ? const _EmptyQuestionsView()
            : _buildQuestionList(),
      ),
    );
  }

  AppBar _buildAppBar() => AppBar(
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
            Text('Questions', style: AppTextStyles.h2),
            Text(widget.quiz.title,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: _isAdding ? null : _addQuestion,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _isAdding
                      ? AppColors.primary.withOpacity(0.5)
                      : AppColors.primary,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: _isAdding
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Row(children: [
                        const Icon(Icons.add_rounded,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 4),
                        Text('Add',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            )),
                      ]),
              ),
            ),
          ),
        ],
      );

  Widget _buildQuestionList() => ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _questions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => QuestionCardOfCreation(
          question: _questions[i],
          index: i,
          onDelete: _questions[i].id.startsWith('temp_')
              ? null
              : () => _deleteQuestion(i),
        ),
      );
}

// ─────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────
class _EmptyQuestionsView extends StatelessWidget {
  const _EmptyQuestionsView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.help_outline_rounded,
              size: 56, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text('No questions yet', style: AppTextStyles.h2),
          const SizedBox(height: 8),
          Text('Tap "Add" to add your first question',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
