import 'package:e_learning/core/constants/app_constants.dart';
import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/features/home/presentaion/cubit/home_cubit.dart';
import 'package:e_learning/features/home/presentaion/cubit/home_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeSearchBar extends StatefulWidget {
  const HomeSearchBar({super.key});

  @override
  State<HomeSearchBar> createState() => _HomeSearchBarState();
}

class _HomeSearchBarState extends State<HomeSearchBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.horizontalPadding),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: TextField(
          controller: _controller,
          onChanged: (v) => context.read<HomeCubit>().searchCourses(v),
          style: AppTextStyles.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Search courses...',
            hintStyle:
                AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
            prefixIcon: const Icon(Icons.search_rounded,
                color: AppColors.textHint, size: 20),
            suffixIcon: BlocBuilder<HomeCubit, HomeState>(
              builder: (ctx, state) {
                final query =
                    state is HomeLoaded ? state.searchQuery : '';
                if (query.isEmpty) return const SizedBox.shrink();
                return GestureDetector(
                  onTap: () {
                    _controller.clear();
                    ctx.read<HomeCubit>().searchCourses('');
                  },
                  child: const Icon(Icons.close_rounded,
                      color: AppColors.textHint, size: 18),
                );
              },
            ),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }
}