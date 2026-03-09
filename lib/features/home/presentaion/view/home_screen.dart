import 'package:e_learning/core/constants/app_constants.dart';
import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/features/courses/data/repo/course_repo.dart';
import 'package:e_learning/features/home/presentaion/cubit/home_cubit.dart';
import 'package:e_learning/features/home/presentaion/cubit/home_states.dart';
import 'package:e_learning/features/home/presentaion/view/widgets/home/home_app_bar.dart';
import 'package:e_learning/features/home/presentaion/view/widgets/home/home_category_selector.dart';
import 'package:e_learning/features/home/presentaion/view/widgets/home/home_courses_list.dart';
import 'package:e_learning/features/home/presentaion/view/widgets/home/home_error_view.dart';
import 'package:e_learning/features/home/presentaion/view/widgets/home/home_featured_courses_list.dart';
import 'package:e_learning/features/home/presentaion/view/widgets/home/home_search_bar.dart';
import 'package:e_learning/features/home/presentaion/view/widgets/home/home_shimmer.dart';
import 'package:e_learning/features/notificatio/presentation/logic/notification_cubit.dart';
import 'package:e_learning/features/notificatio/presentation/logic/notification_states.dart';
import 'package:e_learning/core/networking/notification_banner_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => HomeCubit(CoursesRepo())..fetchCourses(),
        ),
      ],
      child: const _HomeListener(),
    );
  }
}

class _HomeListener extends StatelessWidget {
  const _HomeListener();

  @override
  Widget build(BuildContext context) {
    return BlocListener<NotificationCubit, NotificationState>(
      listener: (context, state) {
        if (state is NotificationLoaded && state.notifications.isNotEmpty) {
          final latest = state.notifications.first;
          final isNew =
              DateTime.now().difference(latest.createdAt).inSeconds < 5;
          if (!latest.isRead && isNew) {
            NotificationBannerService.show(
              context,
              title: latest.title,
              body: latest.body,
              type: latest.type,
            );
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: BlocBuilder<HomeCubit, HomeState>(
            builder: (context, state) {
              if (state is HomeLoading || state is HomeInitial) {
                return const HomeShimmer();
              }
              if (state is HomeError) {
                return HomeErrorView(
                  exception: state.exception,
                  message: state.message,
                  onRetry: () => context.read<HomeCubit>().fetchCourses(),
                );
              }
              return const _HomeContent();
            },
          ),
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(child: HomeAppBar()),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        const SliverToBoxAdapter(child: HomeSearchBar()),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        const SliverToBoxAdapter(child: HomeCategorySelector()),
        const SliverToBoxAdapter(child: SizedBox(height: 28)),

        // Featured label
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.horizontalPadding),
            child: Row(children: [
              Container(
                width: 3,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              const SizedBox(width: 8),
              Text('Featured', style: AppTextStyles.h2),
            ]),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 14)),
        const SliverToBoxAdapter(child: HomeFeaturedCoursesList()),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),

        // All Courses label + count
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.horizontalPadding),
            child: Row(children: [
              Container(
                width: 3,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              const SizedBox(width: 8),
              Text('All Courses', style: AppTextStyles.h2),
              const Spacer(),
              BlocBuilder<HomeCubit, HomeState>(
                builder: (ctx, state) {
                  final count = state is HomeLoaded
                      ? ctx.read<HomeCubit>().filteredCourses.length
                      : 0;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      '$count courses',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ]),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 14)),

        const HomeCoursesList(),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }
}