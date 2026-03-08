import 'package:e_learning/core/erros/app_error_widget.dart';
import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/features/quiz/data/model/quiz_model.dart';
import 'package:e_learning/features/quiz/data/repo/quiz_repo.dart';
import 'package:e_learning/features/quiz/presentation/logic/quiz_cubit.dart';
import 'package:e_learning/features/quiz/presentation/logic/quiz_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Quiz Screen
// ─────────────────────────────────────────────────────────────────────────────
class QuizScreen extends StatelessWidget {
  final QuizModel quiz;
  final VoidCallback? onComplete;

  const QuizScreen({super.key, required this.quiz, this.onComplete});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => QuizCubit(QuizRepo())..startQuiz(quiz),
      child: _QuizBody(onComplete: onComplete),
    );
  }
}

class _QuizBody extends StatelessWidget {
  final VoidCallback? onComplete;
  const _QuizBody({this.onComplete});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<QuizCubit, QuizState>(
      listener: (context, state) {
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

        // ✅ لو حصل error أثناء الـ quiz (نادر) — نعرض snackbar بدل ما نوقف الـ flow
        if (state is QuizError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.exception.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      },
      builder: (context, state) {
        // ✅ Error full-screen — لو جاء error قبل ما الـ quiz يبدأ
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

        final s = state;
        final q = s.quiz.questions[s.currentIndex];
        final progress = (s.currentIndex + 1) / s.quiz.questions.length;
        final timerProgress = s.secondsLeft / 30;
        final timerColor = s.secondsLeft > 10
            ? AppColors.success
            : s.secondsLeft > 5
                ? AppColors.warning
                : AppColors.error;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => _showExitDialog(context),
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
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.quiz.title,
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
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: timerProgress,
                              strokeWidth: 4,
                              backgroundColor: AppColors.cardBorder,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(timerColor),
                            ),
                            Text('${s.secondsLeft}',
                                style: AppTextStyles.bodySmall.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: timerColor)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          'Question ${s.currentIndex + 1} of ${s.quiz.questions.length}',
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.cardBorder),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.04),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(q.question,
                              style: AppTextStyles.h2.copyWith(height: 1.5)),
                        ),
                        const SizedBox(height: 20),
                        ...['a', 'b', 'c', 'd'].map((letter) => _OptionTile(
                              letter: letter,
                              text: q.optionText(letter),
                              selected: s.selectedAnswer == letter,
                              correct: s.answered && letter == q.correctAnswer,
                              wrong: s.answered &&
                                  s.selectedAnswer == letter &&
                                  letter != q.correctAnswer,
                              onTap: () => context
                                  .read<QuizCubit>()
                                  .selectAnswer(letter),
                            )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
            child: const Text('Exit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Option Tile
// ─────────────────────────────────────────────
class _OptionTile extends StatelessWidget {
  final String letter;
  final String text;
  final bool selected;
  final bool correct;
  final bool wrong;
  final VoidCallback onTap;

  const _OptionTile({
    required this.letter,
    required this.text,
    required this.selected,
    required this.correct,
    required this.wrong,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor = AppColors.cardBorder;
    Color bgColor = AppColors.surface;
    Color letterBg = AppColors.surfaceVariant;
    Color letterColor = AppColors.textSecondary;
    Widget? trailingIcon;

    if (correct) {
      borderColor = AppColors.success;
      bgColor = AppColors.success.withOpacity(0.06);
      letterBg = AppColors.success;
      letterColor = Colors.white;
      trailingIcon = const Icon(Icons.check_circle_rounded,
          color: AppColors.success, size: 22);
    } else if (wrong) {
      borderColor = AppColors.error;
      bgColor = AppColors.error.withOpacity(0.06);
      letterBg = AppColors.error;
      letterColor = Colors.white;
      trailingIcon =
          const Icon(Icons.cancel_rounded, color: AppColors.error, size: 22);
    } else if (selected) {
      borderColor = AppColors.primary;
      bgColor = AppColors.primary.withOpacity(0.06);
      letterBg = AppColors.primary;
      letterColor = Colors.white;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: letterBg,
                  borderRadius: BorderRadius.circular(10)),
              child: Center(
                child: Text(letter.toUpperCase(),
                    style: AppTextStyles.h3.copyWith(color: letterColor)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(text, style: AppTextStyles.bodyLarge)),
            if (trailingIcon != null) ...[
              const SizedBox(width: 8),
              trailingIcon,
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quiz Result Screen
// ─────────────────────────────────────────────────────────────────────────────
class QuizResultScreen extends StatefulWidget {
  final VoidCallback onContinue;

  const QuizResultScreen({super.key, required this.onContinue});

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  bool _showReview = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
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
              body: Center(child: CircularProgressIndicator()));
        }

        final s = state;
        final color = s.passed ? AppColors.success : AppColors.error;
        final emoji = s.passed ? '🎉' : '😔';
        final message = s.passed ? 'Great job!' : 'Keep practicing!';

        return PopScope(
          canPop: false,
          onPopInvoked: (didPop) {
            if (!didPop) widget.onContinue();
          },
          child: Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: _showReview
                  ? _ReviewSection(
                      quiz: s.quiz,
                      answers: s.answers,
                      onBack: () => setState(() => _showReview = false),
                    )
                  : SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            const SizedBox(height: 32),

                            FadeTransition(
                              opacity: _fadeAnim,
                              child: ScaleTransition(
                                scale: _scaleAnim,
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
                                    border: Border.all(
                                        color: color.withOpacity(0.3),
                                        width: 3),
                                  ),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Text(emoji,
                                          style: const TextStyle(
                                              fontSize: 36)),
                                      Text('${s.percentage}%',
                                          style: AppTextStyles.displayMedium
                                              .copyWith(color: color)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            FadeTransition(
                              opacity: _fadeAnim,
                              child: Column(
                                children: [
                                  Text(message,
                                      style: AppTextStyles.h1
                                          .copyWith(color: color)),
                                  const SizedBox(height: 8),
                                  Text(
                                    s.passed
                                        ? 'You passed with ${s.score}/${s.total} correct'
                                        : 'You got ${s.score}/${s.total}. Need ${s.quiz.passScore}% to pass',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.textSecondary),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),

                            FadeTransition(
                              opacity: _fadeAnim,
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: AppColors.cardBorder),
                                ),
                                child: Row(
                                  children: [
                                    _ResultStat(
                                        icon: Icons
                                            .check_circle_outline_rounded,
                                        value: '${s.score}',
                                        label: 'Correct',
                                        color: AppColors.success),
                                    _ResultStat(
                                        icon: Icons.cancel_outlined,
                                        value: '${s.total - s.score}',
                                        label: 'Wrong',
                                        color: AppColors.error),
                                    _ResultStat(
                                        icon: Icons.emoji_events_outlined,
                                        value: '${s.quiz.passScore}%',
                                        label: 'Pass score',
                                        color: AppColors.warning),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),

                            FadeTransition(
                              opacity: _fadeAnim,
                              child: Column(
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () => setState(
                                        () => _showReview = true),
                                    icon: const Icon(Icons.list_alt_rounded),
                                    label: const Text('Review Answers'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      side: const BorderSide(
                                          color: AppColors.primary),
                                      minimumSize:
                                          const Size(double.infinity, 52),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14)),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  if (!s.passed)
                                    ElevatedButton.icon(
                                      onPressed: () => context
                                          .read<QuizCubit>()
                                          .retryQuiz(),
                                      icon:
                                          const Icon(Icons.refresh_rounded),
                                      label: const Text('Try Again'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.warning,
                                        minimumSize:
                                            const Size(double.infinity, 52),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14)),
                                      ),
                                    ),
                                  const SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    onPressed: widget.onContinue,
                                    icon: const Icon(
                                        Icons.arrow_forward_rounded),
                                    label: Text(s.passed
                                        ? 'Continue Learning'
                                        : 'Continue Anyway'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: s.passed
                                          ? AppColors.primary
                                          : AppColors.textSecondary,
                                      minimumSize:
                                          const Size(double.infinity, 52),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _ResultStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _ResultStat(
      {required this.icon,
      required this.value,
      required this.label,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 6),
          Text(value, style: AppTextStyles.h2.copyWith(color: color)),
          Text(label,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Review Section
// ─────────────────────────────────────────────
class _ReviewSection extends StatelessWidget {
  final QuizModel quiz;
  final Map<int, String> answers;
  final VoidCallback onBack;

  const _ReviewSection(
      {required this.quiz, required this.answers, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
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
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 16),
                ),
              ),
              const SizedBox(width: 12),
              Text('Review Answers', style: AppTextStyles.h2),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: quiz.questions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (_, i) {
              final q = quiz.questions[i];
              final userAnswer = answers[i];
              final correct = userAnswer == q.correctAnswer;

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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: correct
                                ? AppColors.success.withOpacity(0.1)
                                : AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text('Q${i + 1}',
                              style: AppTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: correct
                                      ? AppColors.success
                                      : AppColors.error)),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          correct
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          color:
                              correct ? AppColors.success : AppColors.error,
                          size: 18,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(q.question, style: AppTextStyles.h3),
                    const SizedBox(height: 12),
                    if (!correct && userAnswer != null)
                      _ReviewAnswer(
                        letter: userAnswer,
                        text: q.optionText(userAnswer),
                        isCorrect: false,
                        label: 'Your answer',
                      ),
                    _ReviewAnswer(
                      letter: q.correctAnswer,
                      text: q.optionText(q.correctAnswer),
                      isCorrect: true,
                      label: 'Correct answer',
                    ),
                    if (userAnswer == null)
                      Text('⏰ Time expired',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.error)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ReviewAnswer extends StatelessWidget {
  final String letter;
  final String text;
  final bool isCorrect;
  final String label;
  const _ReviewAnswer(
      {required this.letter,
      required this.text,
      required this.isCorrect,
      required this.label});

  @override
  Widget build(BuildContext context) {
    final color = isCorrect ? AppColors.success : AppColors.error;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                color: color, borderRadius: BorderRadius.circular(8)),
            child: Center(
              child: Text(letter.toUpperCase(),
                  style: AppTextStyles.caption.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w800)),
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