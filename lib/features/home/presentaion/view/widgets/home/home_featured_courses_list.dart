import 'package:e_learning/core/constants/app_constants.dart';
import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/features/courses/data/model/courses.dart';
import 'package:e_learning/features/home/presentaion/cubit/home_cubit.dart';
import 'package:e_learning/features/home/presentaion/cubit/home_states.dart';
import 'package:e_learning/features/home/presentaion/view/courses_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeFeaturedCoursesList extends StatelessWidget {
  const HomeFeaturedCoursesList({super.key});

  void _openDetails(BuildContext context, CourseModel course) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CourseDetailsScreen(course: course)),
    ).then((_) {
      if (context.mounted) context.read<HomeCubit>().fetchCourses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        if (state is! HomeLoaded) return const SizedBox.shrink();
        final featured = state.featuredCourses;
        if (featured.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: 190,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.horizontalPadding),
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemCount: featured.length,
            itemBuilder: (_, i) => HomeFeaturedCard(
              course: featured[i],
              onTap: () => _openDetails(context, featured[i]),
            ),
          ),
        );
      },
    );
  }
}

class HomeFeaturedCard extends StatelessWidget {
  final CourseModel course;
  final VoidCallback onTap;

  const HomeFeaturedCard({
    super.key,
    required this.course,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 240,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 16,
                offset: const Offset(0, 6)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              course.thumbnailUrl.isNotEmpty
                  ? Image.network(course.thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _gradientBg())
                  : _gradientBg(),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.78),
                    ],
                    stops: const [0.3, 1.0],
                  ),
                ),
              ),
              Positioned(
                bottom: 14,
                left: 14,
                right: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        course.category,
                        style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 10),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      course.title,
                      style: AppTextStyles.h3.copyWith(color: Colors.white),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Color(0xFFFBBF24), size: 13),
                        const SizedBox(width: 3),
                        Text(
                          course.rating.toStringAsFixed(1),
                          style: AppTextStyles.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.schedule_outlined,
                            color: Colors.white60, size: 12),
                        const SizedBox(width: 3),
                        Text(
                          course.duration,
                          style: AppTextStyles.caption
                              .copyWith(color: Colors.white60),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gradientBg() => Container(
        decoration:
            const BoxDecoration(gradient: AppColors.primaryGradient),
        child: const Center(
            child: Icon(Icons.school_outlined,
                color: Colors.white38, size: 48)),
      );
}