// widgets/saved_courses_body.dart

import 'package:e_learning/core/erros/app_error_widget.dart';
import 'package:e_learning/core/erros/app_exceptions.dart';
import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/features/courses/data/model/courses.dart';
import 'package:e_learning/features/home/presentaion/view/courses_details.dart';
import 'package:e_learning/features/watchlist/presentation/logic/wishlist_cubit.dart';
import 'package:e_learning/features/watchlist/presentation/logic/wishlist_states.dart';
import 'package:e_learning/features/watchlist/presentation/view/widgets/saved_course_card.dart';
import 'package:e_learning/features/watchlist/presentation/view/widgets/saved_courses_empty.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SavedCoursesBody extends StatelessWidget {
  const SavedCoursesBody({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<WishlistCubit>().userId;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<WishlistCubit, WishlistState>(
        builder: (context, state) {
          final isLoading = state is WishlistLoading;
          final courses =
              state is WishlistLoaded ? state.courses : <CourseModel>[];

          return CustomScrollView(
            slivers: [
              _SavedCoursesAppBar(),
              _CoursesCountHeader(count: courses.length),
              _buildContent(context, state, courses, isLoading, userId),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WishlistState state,
    List<CourseModel> courses,
    bool isLoading,
    String userId,
  ) {
    if (state is WishlistError) {
      return SliverFillRemaining(
        child: AppErrorWidget(
          exception: UnknownException(state.message),
          onRetry: () => context.read<WishlistCubit>().reload(),
        ),
      );
    }

    if (isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (courses.isEmpty) {
      return const SliverFillRemaining(child: SavedCoursesEmpty());
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (ctx, i) => SavedCourseCard(
            course: courses[i],
            onTap: () => Navigator.push(
              ctx,
              MaterialPageRoute(
                builder: (_) => CourseDetailsScreen(
                  course: courses[i],
                  userId: userId,
                ),
              ),
            ),
            onRemove: () =>
                context.read<WishlistCubit>().toggle(courses[i]),
          ),
          childCount: courses.length,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// App Bar
// ─────────────────────────────────────────────
class _SavedCoursesAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
      title: Text('Saved Courses', style: AppTextStyles.h2),
      centerTitle: false,
    );
  }
}

// ─────────────────────────────────────────────
// Courses Count Header
// ─────────────────────────────────────────────
class _CoursesCountHeader extends StatelessWidget {
  final int count;
  const _CoursesCountHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Text(
          '$count course${count != 1 ? 's' : ''} saved',
          style: AppTextStyles.bodyMedium
              .copyWith(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}