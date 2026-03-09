import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/features/courses/data/model/courses.dart';
import 'package:e_learning/features/watchlist/presentation/logic/wishlist_cubit.dart';
import 'package:e_learning/features/watchlist/presentation/logic/wishlist_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CourseHeroAppBar extends StatelessWidget {
  final CourseModel course;
  final String userId;

  const CourseHeroAppBar({
    super.key,
    required this.course,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 18),
        ),
      ),
      actions: [
        BlocBuilder<WishlistCubit, WishlistState>(
          builder: (ctx, state) {
            final saved = ctx.read<WishlistCubit>().isSaved(course.id);
            return GestureDetector(
              onTap: () async {
                if (userId.isEmpty) return;
                await ctx.read<WishlistCubit>().toggle(course);
                if (ctx.mounted) {
                  final nowSaved =
                      ctx.read<WishlistCubit>().isSaved(course.id);
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                    content: Text(nowSaved
                        ? 'Saved to wishlist ❤️'
                        : 'Removed from wishlist'),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 1),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ));
                }
              },
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: saved
                      ? Colors.white.withOpacity(0.25)
                      : Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(8),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    saved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    key: ValueKey(saved),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            );
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              course.thumbnailUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration:
                    const BoxDecoration(gradient: AppColors.primaryGradient),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.5),
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