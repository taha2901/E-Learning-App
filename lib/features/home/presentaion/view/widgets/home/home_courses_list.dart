import 'package:e_learning/core/constants/app_constants.dart';
import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/features/courses/data/model/courses.dart';
import 'package:e_learning/features/courses/presentation/cubit/course_cubit.dart';
import 'package:e_learning/features/home/presentaion/cubit/home_cubit.dart';
import 'package:e_learning/features/home/presentaion/cubit/home_states.dart';
import 'package:e_learning/features/home/presentaion/view/courses_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeCoursesList extends StatelessWidget {
  const HomeCoursesList({super.key});

  void _openDetails(BuildContext context, CourseModel course) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<CoursesCubit>(),
          child: CourseDetailsScreen(course: course),
        ),
      ),
    ).then((_) {
      if (context.mounted) context.read<HomeCubit>().fetchCourses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        if (state is! HomeLoaded) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }
        final courses = context.read<HomeCubit>().filteredCourses;

        if (courses.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 48),
              child: Column(
                children: [
                  Icon(Icons.search_off_rounded,
                      size: 52, color: AppColors.textHint),
                  const SizedBox(height: 12),
                  Text(
                    'No courses found',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.horizontalPadding),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: HomeCourseRowCard(
                  course: courses[i],
                  onTap: () => _openDetails(ctx, courses[i]),
                ),
              ),
              childCount: courses.length,
            ),
          ),
        );
      },
    );
  }
}

class HomeCourseRowCard extends StatelessWidget {
  final CourseModel course;
  final VoidCallback onTap;

  const HomeCourseRowCard({
    super.key,
    required this.course,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 82,
                height: 82,
                child: course.thumbnailUrl.isNotEmpty
                    ? Image.network(course.thumbnailUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _thumbFallback())
                    : _thumbFallback(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.category.toUpperCase(),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 9,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(course.title,
                      style: AppTextStyles.h3,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(course.instructor,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: Color(0xFFFBBF24), size: 13),
                      const SizedBox(width: 2),
                      Text(
                        course.rating.toStringAsFixed(1),
                        style: AppTextStyles.caption
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: BoxDecoration(
                            color: AppColors.textHint,
                            shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text(course.duration,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textSecondary)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          course.level,
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbFallback() => Container(
        decoration:
            const BoxDecoration(gradient: AppColors.primaryGradient),
        child: const Center(
            child: Icon(Icons.play_lesson_outlined,
                color: Colors.white54, size: 28)),
      );
}