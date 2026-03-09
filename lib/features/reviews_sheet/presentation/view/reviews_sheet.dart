import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/features/courses/data/model/review_model.dart';
import 'package:e_learning/features/courses/data/repo/review_repo.dart';
import 'package:e_learning/features/courses/presentation/cubit/review_cubit.dart';
import 'package:e_learning/features/courses/presentation/cubit/review_states.dart';
import 'package:e_learning/features/reviews_sheet/presentation/view/widgets/reviews_empty_state.dart';
import 'package:e_learning/features/reviews_sheet/presentation/view/widgets/reviews_my_review_card.dart';
import 'package:e_learning/features/reviews_sheet/presentation/view/widgets/reviews_rating_summary.dart';
import 'package:e_learning/features/reviews_sheet/presentation/view/widgets/reviews_review_card.dart';
import 'package:e_learning/features/reviews_sheet/presentation/view/widgets/reviews_write_button.dart';
import 'package:e_learning/features/reviews_sheet/presentation/view/widgets/reviews_write_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ── Entry point ────────────────────────────────────────────────────
// Returns new rating if user submitted/edited/deleted, or null
Future<double?> showReviewsSheet(
  BuildContext context, {
  required String courseId,
  required String userId,
  required String courseTitle,
}) {
  return showModalBottomSheet<double>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => BlocProvider(
      create: (_) => ReviewCubit(
        ReviewRepo(),
        courseId: courseId,
        userId: userId,
      )..load(),
      child: _ReviewsSheet(courseTitle: courseTitle),
    ),
  );
}

// ── Sheet ──────────────────────────────────────────────────────────
class _ReviewsSheet extends StatelessWidget {
  final String courseTitle;

  const _ReviewsSheet({required this.courseTitle});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (ctx, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: BlocConsumer<ReviewCubit, ReviewState>(
          listenWhen: (prev, curr) =>
              prev is ReviewSubmitting && curr is ReviewLoaded,
          listener: (context, state) async {
            if (state is ReviewLoaded) {
              final newRating =
                  await context.read<ReviewCubit>().getUpdatedRating();
              if (context.mounted) Navigator.pop(context, newRating);
            }
          },
          builder: (context, state) => Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.cardBorder,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Reviews', style: AppTextStyles.h1),
                          Text(
                            courseTitle,
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.divider),

              Expanded(child: _buildBody(context, state, scrollCtrl)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ReviewState state,
    ScrollController scrollCtrl,
  ) {
    if (state is ReviewLoading || state is ReviewSubmitting) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (state is ReviewError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text(state.message, style: AppTextStyles.bodyMedium),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<ReviewCubit>().load(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state is ReviewLoaded) {
      return ListView(
        controller: scrollCtrl,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          const SizedBox(height: 8),
          RatingSummary(summary: state.summary),
          const SizedBox(height: 20),
          if (state.myReview == null)
            WriteReviewButton(onTap: () => _openWriteSheet(context))
          else
            MyReviewCard(
              review: state.myReview!,
              onEdit: () =>
                  _openWriteSheet(context, existing: state.myReview),
              onDelete: () =>
                  context.read<ReviewCubit>().deleteReview(state.myReview!.id),
            ),
          const SizedBox(height: 20),
          if (state.reviews.isEmpty)
            const EmptyReviews()
          else ...[
            Text('${state.summary.totalReviews} Reviews',
                style: AppTextStyles.h2),
            const SizedBox(height: 12),
            ...state.reviews.map((r) => ReviewCard(review: r)),
          ],
          const SizedBox(height: 32),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  void _openWriteSheet(BuildContext context, {ReviewModel? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<ReviewCubit>(),
        child: WriteReviewSheet(existing: existing),
      ),
    );
  }
}