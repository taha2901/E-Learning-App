import 'package:e_learning/core/constants/app_constants.dart';
import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/features/home/presentaion/cubit/home_cubit.dart';
import 'package:e_learning/features/home/presentaion/cubit/home_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeCategorySelector extends StatelessWidget {
  static const _categories = [
    'All', 'Mobile Dev', 'Web Dev', 'Design', 'Data Science', 'AI & ML',
  ];

  const HomeCategorySelector({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        final selected =
            state is HomeLoaded ? state.selectedCategory : 'All';
        return SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.horizontalPadding),
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final cat = _categories[i];
              final sel = selected == cat;
              return GestureDetector(
                onTap: () =>
                    context.read<HomeCubit>().selectCategory(cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                        color: sel
                            ? AppColors.primary
                            : AppColors.cardBorder),
                  ),
                  child: Center(
                    child: Text(
                      cat,
                      style: AppTextStyles.caption.copyWith(
                        color: sel ? Colors.white : AppColors.textSecondary,
                        fontWeight:
                            sel ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}