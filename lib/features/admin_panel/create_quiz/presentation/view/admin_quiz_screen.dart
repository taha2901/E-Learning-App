import 'package:e_learning/core/erros/app_error_widget.dart';
import 'package:e_learning/core/erros/app_exceptions.dart';
import 'package:e_learning/core/erros/network_exception_handler.dart';
import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/features/quiz/data/model/quiz_model.dart';
import 'package:e_learning/features/quiz/data/repo/quiz_repo.dart';
import 'package:e_learning/features/quiz/presentation/logic/quiz_cubit.dart';
import 'package:e_learning/features/quiz/presentation/logic/quiz_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Admin Quiz Manager Screen
// ─────────────────────────────────────────────────────────────────────────────
class AdminQuizScreen extends StatelessWidget {
  const AdminQuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => QuizCubit(QuizRepo())..loadAllQuizzes(),
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
      body: BlocBuilder<QuizCubit, QuizState>(
        builder: (context, state) {
          // ✅ Error State
          if (state is AdminQuizError) {
            return CustomScrollView(
              slivers: [
                _buildAppBar(context, 0, context.read<QuizCubit>()),
                SliverFillRemaining(
                  child: AppErrorWidget(
                    exception: state.exception,
                    onRetry: () =>
                        context.read<QuizCubit>().loadAllQuizzes(),
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
              _buildAppBar(context, quizzes.length, context.read<QuizCubit>()),
              if (isLoading)
                const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()))
              else if (quizzes.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.06),
                              shape: BoxShape.circle),
                          child: const Icon(Icons.quiz_outlined,
                              size: 48, color: AppColors.primary),
                        ),
                        const SizedBox(height: 20),
                        Text('No quizzes yet', style: AppTextStyles.h2),
                        const SizedBox(height: 8),
                        Text('Tap "New Quiz" to create your first quiz',
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _QuizAdminCard(
                        quiz: quizzes[i],
                        onEdit: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: context.read<QuizCubit>(),
                                child: AddQuestionsScreen(quiz: quizzes[i]),
                              ),
                            ),
                          );
                          context.read<QuizCubit>().loadAllQuizzes();
                        },
                        onDelete: () async {
                          try {
                            await context
                                .read<QuizCubit>()
                                .deleteQuiz(quizzes[i].id);
                          } on AppException catch (e) {
                            if (ctx.mounted) {
                              _showErrorSnack(ctx, e.message);
                            }
                          }
                        },
                      ),
                      childCount: quizzes.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  SliverAppBar _buildAppBar(
      BuildContext context, int count, QuizCubit cubit) {
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
              child: Row(children: [
                const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 4),
                Text('New Quiz',
                    style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ]),
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
// Quiz Admin Card
// ─────────────────────────────────────────────
class _QuizAdminCard extends StatelessWidget {
  final QuizModel quiz;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _QuizAdminCard(
      {required this.quiz, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.quiz_rounded,
                  color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(quiz.title, style: AppTextStyles.h3),
                  const SizedBox(height: 2),
                  Text(
                      '${quiz.questions.length} questions • Pass: ${quiz.passScore}%',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            Row(children: [
              _ActionBtn(
                  icon: Icons.edit_rounded,
                  color: AppColors.primary,
                  onTap: onEdit),
              const SizedBox(width: 8),
              _ActionBtn(
                  icon: Icons.delete_outline_rounded,
                  color: AppColors.error,
                  onTap: () => _confirmDelete(context)),
            ]),
          ]),
          if (quiz.questions.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 12),
            ...quiz.questions.take(2).map((q) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6)),
                      child: Center(
                        child: Text('${quiz.questions.indexOf(q) + 1}',
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(q.question,
                            style: AppTextStyles.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis)),
                  ]),
                )),
            if (quiz.questions.length > 2)
              Text('+ ${quiz.questions.length - 2} more questions',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textHint)),
          ],
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Quiz?', style: AppTextStyles.h2),
        content: Text('This will delete "${quiz.title}" and all its questions.',
            style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add Questions Screen — with error handling
// ─────────────────────────────────────────────────────────────────────────────
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

  Future<void> _addQuestion() async {
    if (_isAdding) return;

    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _AddQuestionSheet(),
    );

    if (result != null && mounted) {
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
        await context.read<QuizCubit>().addQuestion(
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
        // ✅ Rollback الـ optimistic update لو فشل
        if (mounted) {
          setState(() {
            _questions =
                _questions.where((q) => !q.id.startsWith('temp_')).toList();
          });
          _showErrorSnack(e.message);
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _questions =
                _questions.where((q) => !q.id.startsWith('temp_')).toList();
          });
          _showErrorSnack(NetworkExceptionHandler.handle(e).message);
        }
      }

      if (mounted) setState(() => _isAdding = false);
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

  @override
  Widget build(BuildContext context) {
    return BlocListener<QuizCubit, QuizState>(
      listenWhen: (_, curr) => curr is AdminQuizSaved,
      listener: (context, state) {
        if (state is AdminQuizSaved) {
          setState(() => _questions = List.from(state.quiz.questions));
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.cardBorder)),
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
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Row(children: [
                          const Icon(Icons.add_rounded,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 4),
                          Text('Add',
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                        ]),
                ),
              ),
            ),
          ],
        ),
        body: _questions.isEmpty
            ? Center(
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
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _questions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _QuestionCard(
                  question: _questions[i],
                  index: i,
                  onDelete: _questions[i].id.startsWith('temp_')
                      ? null
                      : () async {
                          final removed = _questions[i];
                          setState(() {
                            _questions = List.from(_questions)..removeAt(i);
                          });
                          try {
                            await context.read<QuizCubit>().deleteQuestion(
                                removed.id, widget.quiz.videoId);
                          } on AppException catch (e) {
                            // ✅ Rollback لو فشل الـ delete
                            if (mounted) {
                              setState(() {
                                _questions = List.from(_questions)
                                  ..insert(i, removed);
                              });
                              _showErrorSnack(e.message);
                            }
                          }
                        },
                ),
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Question Card
// ─────────────────────────────────────────────
class _QuestionCard extends StatelessWidget {
  final QuizQuestion question;
  final int index;
  final VoidCallback? onDelete;

  const _QuestionCard(
      {required this.question,
      required this.index,
      required this.onDelete});

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
                  : AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(100)),
                child: Text('Q${index + 1}',
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700)),
              ),
              if (isTemp) ...[
                const SizedBox(width: 8),
                const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary)),
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
                        borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: AppColors.error, size: 16),
                  ),
                ),
            ]),
            const SizedBox(height: 10),
            Text(question.question, style: AppTextStyles.h3),
            const SizedBox(height: 12),
            ...['a', 'b', 'c', 'd'].map(
              (l) => _AnswerRow(
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
}

class _AnswerRow extends StatelessWidget {
  final String letter;
  final String text;
  final bool isCorrect;
  const _AnswerRow(
      {required this.letter, required this.text, required this.isCorrect});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
              color: isCorrect ? AppColors.success : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8)),
          child: Center(
            child: Text(letter.toUpperCase(),
                style: AppTextStyles.caption.copyWith(
                    color: isCorrect ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
            child: Text(text,
                style: AppTextStyles.bodySmall.copyWith(
                    color: isCorrect
                        ? AppColors.success
                        : AppColors.textPrimary))),
        if (isCorrect)
          const Icon(Icons.check_rounded, color: AppColors.success, size: 16),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add Question Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _AddQuestionSheet extends StatefulWidget {
  const _AddQuestionSheet();

  @override
  State<_AddQuestionSheet> createState() => _AddQuestionSheetState();
}

class _AddQuestionSheetState extends State<_AddQuestionSheet> {
  final _questionCtrl = TextEditingController();
  final _aCtrl = TextEditingController();
  final _bCtrl = TextEditingController();
  final _cCtrl = TextEditingController();
  final _dCtrl = TextEditingController();
  String _correct = 'a';
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _questionCtrl.dispose();
    _aCtrl.dispose();
    _bCtrl.dispose();
    _cCtrl.dispose();
    _dCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.cardBorder,
                      borderRadius: BorderRadius.circular(100)),
                ),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Text('Add Question', style: AppTextStyles.h2),
                const Spacer(),
                IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context)),
              ]),
              const SizedBox(height: 16),
              TextFormField(
                controller: _questionCtrl,
                maxLines: 2,
                decoration: _inputDeco('Question', Icons.help_outline_rounded),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Text('Options', style: AppTextStyles.h3),
              const SizedBox(height: 10),
              ...['a', 'b', 'c', 'd'].map((l) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(children: [
                      GestureDetector(
                        onTap: () => setState(() => _correct = l),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                              color: _correct == l
                                  ? AppColors.success
                                  : AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(8)),
                          child: Center(
                              child: Text(l.toUpperCase(),
                                  style: AppTextStyles.caption.copyWith(
                                      color: _correct == l
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                      fontWeight: FontWeight.w700))),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _ctrl(l),
                          decoration:
                              _inputDeco('Option ${l.toUpperCase()}', null),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ]),
                  )),
              const SizedBox(height: 4),
              Text('Tap a letter to mark it as correct answer',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textHint)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.pop(context, {
                        'question': _questionCtrl.text.trim(),
                        'a': _aCtrl.text.trim(),
                        'b': _bCtrl.text.trim(),
                        'c': _cCtrl.text.trim(),
                        'd': _dCtrl.text.trim(),
                        'correct': _correct,
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                  child:
                      Text('Add Question', style: AppTextStyles.labelLarge),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextEditingController _ctrl(String l) {
    switch (l) {
      case 'a': return _aCtrl;
      case 'b': return _bCtrl;
      case 'c': return _cCtrl;
      default:  return _dCtrl;
    }
  }

  InputDecoration _inputDeco(String label, IconData? icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Create Quiz Screen — with error handling
// ─────────────────────────────────────────────────────────────────────────────
class CreateQuizScreen extends StatefulWidget {
  const CreateQuizScreen({super.key});

  @override
  State<CreateQuizScreen> createState() => _CreateQuizScreenState();
}

class _CreateQuizScreenState extends State<CreateQuizScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _passCtrl = TextEditingController(text: '70');

  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _videos = [];
  String? _selectedCourseId;
  String? _selectedVideoId;
  bool _loadingCourses = true;
  bool _loadingVideos = false;
  bool _saving = false;
  String? _loadCoursesError;

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchCourses() async {
    setState(() {
      _loadingCourses = true;
      _loadCoursesError = null;
    });
    try {
      final res = await Supabase.instance.client
          .from('courses')
          .select('id, title')
          .order('title') as List;
      if (mounted) {
        setState(() {
          _courses = res.cast<Map<String, dynamic>>();
          _loadingCourses = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingCourses = false;
          _loadCoursesError =
              NetworkExceptionHandler.handle(e).message;
        });
      }
    }
  }

  Future<void> _onCourseSelected(String courseId) async {
    setState(() {
      _selectedCourseId = courseId;
      _selectedVideoId = null;
      _videos = [];
      _loadingVideos = true;
    });
    try {
      final videos = await QuizRepo().fetchVideosForCourse(courseId);
      if (mounted) {
        setState(() {
          _videos = videos;
          _loadingVideos = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingVideos = false);
        _showSnack(NetworkExceptionHandler.handle(e).message, isError: true);
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCourseId == null || _selectedVideoId == null) {
      _showSnack('Please select a course and a video', isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final quiz = await context.read<QuizCubit>().createQuiz(
            videoId: _selectedVideoId!,
            courseId: _selectedCourseId!,
            title: _titleCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            passScore: int.tryParse(_passCtrl.text) ?? 70,
          );
      if (quiz != null && mounted) {
        _showSnack('Quiz created successfully!');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<QuizCubit>(),
              child: AddQuestionsScreen(quiz: quiz),
            ),
          ),
        );
      } else {
        _showSnack('Failed to create quiz', isError: true);
      }
    } on AppException catch (e) {
      _showSnack(e.message, isError: true);
    } catch (e) {
      _showSnack(NetworkExceptionHandler.handle(e).message, isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    // ✅ لو فشل تحميل الـ courses — اعرض error widget مع retry
    if (_loadCoursesError != null && !_loadingCourses) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          title: Text('Create Quiz', style: AppTextStyles.h2),
        ),
        body: AppErrorWidget(
          exception: UnknownException(_loadCoursesError!),
          onRetry: _fetchCourses,
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.cardBorder)),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 16, color: AppColors.textPrimary),
          ),
        ),
        title: Text('Create Quiz', style: AppTextStyles.h2),
      ),
      body: _loadingCourses
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _SectionCard(
                    title: 'Quiz Info',
                    icon: Icons.info_outline_rounded,
                    children: [
                      _FormField(
                          controller: _titleCtrl,
                          label: 'Quiz Title',
                          hint: 'e.g. Lesson 1 Quiz',
                          icon: Icons.title_rounded,
                          validator: (v) => v!.isEmpty ? 'Required' : null),
                      const SizedBox(height: 14),
                      _FormField(
                          controller: _descCtrl,
                          label: 'Description (optional)',
                          hint: 'Short description...',
                          icon: Icons.description_outlined,
                          maxLines: 2),
                      const SizedBox(height: 14),
                      _FormField(
                        controller: _passCtrl,
                        label: 'Pass Score %',
                        hint: '70',
                        icon: Icons.percent_rounded,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          if (n == null || n < 1 || n > 100) return 'Enter 1-100';
                          return null;
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Assign to Video',
                    icon: Icons.video_library_outlined,
                    children: [
                      _DropdownField(
                        label: 'Select Course',
                        icon: Icons.school_outlined,
                        value: _selectedCourseId,
                        hint: 'Select a course',
                        items: _courses
                            .map((c) => DropdownMenuItem(
                                value: c['id'] as String,
                                child: Text(c['title'] as String,
                                    overflow: TextOverflow.ellipsis)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) _onCourseSelected(v);
                        },
                      ),
                      const SizedBox(height: 14),
                      if (_loadingVideos)
                        const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                                child: CircularProgressIndicator(
                                    strokeWidth: 2)))
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                              border: Border.all(color: AppColors.cardBorder),
                              borderRadius: BorderRadius.circular(12)),
                          child: Row(children: [
                            const Icon(Icons.play_circle_outline_rounded,
                                color: AppColors.textHint, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedVideoId,
                                  isExpanded: true,
                                  hint: Text(
                                    _selectedCourseId == null
                                        ? 'Select a course first'
                                        : _videos.isEmpty
                                            ? 'No videos in this course'
                                            : 'Select a video',
                                    style: AppTextStyles.bodySmall
                                        .copyWith(color: AppColors.textHint),
                                  ),
                                  items: _videos
                                      .map((v) => DropdownMenuItem<String>(
                                          value: v['id'] as String,
                                          child: Text(v['title'] as String,
                                              overflow: TextOverflow.ellipsis)))
                                      .toList(),
                                  onChanged: _videos.isEmpty
                                      ? null
                                      : (val) => setState(
                                          () => _selectedVideoId = val),
                                ),
                              ),
                            ),
                          ]),
                        ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14))),
                      child: _saving
                          ? const CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5)
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.arrow_forward_rounded,
                                    color: Colors.white),
                                const SizedBox(width: 8),
                                Text('Next: Add Questions',
                                    style: AppTextStyles.labelLarge),
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

// ─────────────────────────────────────────────
// Reusable Widgets
// ─────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _SectionCard(
      {required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Text(title, style: AppTextStyles.h3),
          ]),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  const _FormField(
      {required this.controller,
      required this.label,
      required this.hint,
      required this.icon,
      this.maxLines = 1,
      this.keyboardType,
      this.validator});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?>? onChanged;
  final String? hint;
  const _DropdownField(
      {required this.label,
      required this.icon,
      required this.value,
      required this.items,
      required this.onChanged,
      this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(icon, color: AppColors.textHint, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text(hint ?? 'Select $label',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textHint)),
              isExpanded: true,
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ]),
    );
  }
}