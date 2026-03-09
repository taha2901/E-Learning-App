// screens/quiz_screen.dart

import 'package:e_learning/features/quiz/data/model/quiz_model.dart';
import 'package:e_learning/features/quiz/data/repo/quiz_repo.dart';
import 'package:e_learning/features/quiz/presentation/logic/quiz_cubit.dart';
import 'package:e_learning/features/quiz/presentation/view/widgets/quiz_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class QuizScreen extends StatelessWidget {
  final QuizModel quiz;
  final VoidCallback? onComplete;

  const QuizScreen({super.key, required this.quiz, this.onComplete});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => QuizCubit(QuizRepo())..startQuiz(quiz),
      child: QuizBody(onComplete: onComplete),
    );
  }
}