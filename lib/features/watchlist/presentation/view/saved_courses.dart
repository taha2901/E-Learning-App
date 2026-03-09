// screens/saved_courses_screen.dart

import 'package:e_learning/features/courses/data/repo/course_repo.dart';
import 'package:e_learning/features/watchlist/presentation/logic/wishlist_cubit.dart';
import 'package:e_learning/features/watchlist/presentation/view/widgets/saved_courses_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SavedCoursesScreen extends StatelessWidget {
  final String userId;
  const SavedCoursesScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    // Reuse an existing cubit if already provided (e.g. from ProfileScreen)
    final existingCubit = context.read<WishlistCubit?>();

    if (existingCubit != null) {
      existingCubit.load();
      return const SavedCoursesBody();
    }

    return BlocProvider(
      create: (_) =>
          WishlistCubit(CoursesRepo(), userId: userId)..load(),
      child: const SavedCoursesBody(),
    );
  }
}