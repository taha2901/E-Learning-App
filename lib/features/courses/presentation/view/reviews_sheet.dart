// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// reviews_sheet.dart
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/features/courses/data/model/review_model.dart';
import 'package:e_learning/features/courses/data/repo/review_repo.dart';
import 'package:e_learning/features/courses/presentation/cubit/review_cubit.dart';
import 'package:e_learning/features/courses/presentation/cubit/review_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ─────────────────────────────────────────────────────────────────
// ✅ Entry point — بيرجع الـ rating الجديد لو اليوزر عمل review
// ─────────────────────────────────────────────────────────────────
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
      child: _ReviewsSheet(
        courseTitle: courseTitle,
        userId: userId,
        courseId: courseId,
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────
// Main Sheet
// ─────────────────────────────────────────────────────────────────
class _ReviewsSheet extends StatelessWidget {
  final String courseTitle;
  final String userId;
  final String courseId;

  const _ReviewsSheet({
    required this.courseTitle,
    required this.userId,
    required this.courseId,
  });

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
          // ✅ لما يخلص submit بنرجع الـ rating الجديد للـ screen
          listenWhen: (prev, curr) =>
              prev is ReviewSubmitting && curr is ReviewLoaded,
          listener: (context, state) async {
            if (state is ReviewLoaded) {
              final newRating =
                  await context.read<ReviewCubit>().getUpdatedRating();
              if (context.mounted) {
                Navigator.pop(context, newRating);
              }
            }
          },
          builder: (context, state) {
            return Column(
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
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary),
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
                Expanded(child: _buildContent(context, state, scrollCtrl)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, ReviewState state, ScrollController scrollCtrl) {
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
          _RatingSummary(summary: state.summary),
          const SizedBox(height: 20),
          if (state.myReview == null)
            _WriteReviewButton(onTap: () => _showWriteReview(context))
          else
            _MyReviewCard(
              review: state.myReview!,
              onEdit: () =>
                  _showWriteReview(context, existing: state.myReview),
              onDelete: () => context
                  .read<ReviewCubit>()
                  .deleteReview(state.myReview!.id),
            ),
          const SizedBox(height: 20),
          if (state.reviews.isEmpty)
            _EmptyReviews()
          else ...[
            Text('${state.summary.totalReviews} Reviews',
                style: AppTextStyles.h2),
            const SizedBox(height: 12),
            ...state.reviews.map((r) => _ReviewCard(review: r)),
          ],
          const SizedBox(height: 32),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  void _showWriteReview(BuildContext context, {ReviewModel? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<ReviewCubit>(),
        child: _WriteReviewSheet(existing: existing),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Rating Summary
// ─────────────────────────────────────────────────────────────────
class _RatingSummary extends StatelessWidget {
  final ReviewSummary summary;
  const _RatingSummary({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                summary.averageRating.toStringAsFixed(1),
                style: const TextStyle(
                    fontSize: 48, fontWeight: FontWeight.w800),
              ),
              _StarRow(rating: summary.averageRating, size: 18),
              const SizedBox(height: 4),
              Text('${summary.totalReviews} reviews',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              children: [5, 4, 3, 2, 1].map((star) {
                final count = summary.distribution[star] ?? 0;
                final pct = summary.totalReviews == 0
                    ? 0.0
                    : count / summary.totalReviews;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Text('$star',
                          style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary)),
                      const SizedBox(width: 4),
                      const Icon(Icons.star_rounded,
                          size: 12, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 7,
                            backgroundColor: AppColors.cardBorder,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              star >= 4
                                  ? AppColors.success
                                  : star == 3
                                      ? AppColors.warning
                                      : AppColors.error,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 20,
                        child: Text('$count',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textHint),
                            textAlign: TextAlign.right),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Write Review Button
// ─────────────────────────────────────────────────────────────────
class _WriteReviewButton extends StatelessWidget {
  final VoidCallback onTap;
  const _WriteReviewButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.rate_review_rounded,
                  color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Write a Review', style: AppTextStyles.h3),
                  Text('Share your experience with others',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: AppColors.primary, size: 16),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// My Review Card
// ─────────────────────────────────────────────────────────────────
class _MyReviewCard extends StatelessWidget {
  final ReviewModel review;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MyReviewCard(
      {required this.review, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text('Your Review',
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700)),
              ),
              const Spacer(),
              GestureDetector(
                  onTap: onEdit,
                  child: const Icon(Icons.edit_outlined,
                      size: 18, color: AppColors.primary)),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _confirmDelete(context),
                child: const Icon(Icons.delete_outline_rounded,
                    size: 18, color: AppColors.error),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _StarRow(rating: review.rating, size: 16),
          const SizedBox(height: 8),
          Text(review.comment, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Review?', style: AppTextStyles.h2),
        content: Text('Are you sure you want to delete your review?',
            style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Review Card
// ─────────────────────────────────────────────────────────────────
class _ReviewCard extends StatelessWidget {
  final ReviewModel review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final diff = DateTime.now().difference(review.createdAt);
    final timeAgo = diff.inDays > 30
        ? '${(diff.inDays / 30).floor()}mo ago'
        : diff.inDays > 0
            ? '${diff.inDays}d ago'
            : diff.inHours > 0
                ? '${diff.inHours}h ago'
                : 'Just now';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                backgroundImage: review.userAvatar != null &&
                        review.userAvatar!.isNotEmpty
                    ? NetworkImage(review.userAvatar!)
                    : null,
                child: review.userAvatar == null ||
                        review.userAvatar!.isEmpty
                    ? Text(
                        review.userName.isNotEmpty
                            ? review.userName[0].toUpperCase()
                            : 'U',
                        style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700))
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.userName, style: AppTextStyles.h3),
                    Text(timeAgo,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textHint)),
                  ],
                ),
              ),
              _StarRow(rating: review.rating, size: 14),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(review.comment, style: AppTextStyles.bodyMedium),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Empty Reviews
// ─────────────────────────────────────────────────────────────────
class _EmptyReviews extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.reviews_outlined,
                  size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text('No Reviews Yet', style: AppTextStyles.h2),
            const SizedBox(height: 8),
            Text('Be the first to review this course!',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Write Review Sheet
// ─────────────────────────────────────────────────────────────────
class _WriteReviewSheet extends StatefulWidget {
  final ReviewModel? existing;
  const _WriteReviewSheet({this.existing});

  @override
  State<_WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<_WriteReviewSheet> {
  double _rating = 0;
  late final TextEditingController _commentCtrl;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.existing?.rating ?? 0;
    _commentCtrl =
        TextEditingController(text: widget.existing?.comment ?? '');
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(100)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(
                    widget.existing != null
                        ? 'Edit Review'
                        : 'Write a Review',
                    style: AppTextStyles.h1),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Your Rating', style: AppTextStyles.h3),
            const SizedBox(height: 12),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final v = i + 1.0;
                  return GestureDetector(
                    onTap: () => setState(() => _rating = v),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        _rating >= v
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: _rating >= v
                            ? const Color(0xFFF59E0B)
                            : AppColors.cardBorder,
                        size: 44,
                      ),
                    ),
                  );
                }),
              ),
            ),
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(_ratingLabel(_rating),
                    key: ValueKey(_rating),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: _rating >= 4
                          ? AppColors.success
                          : _rating >= 3
                              ? AppColors.warning
                              : _rating > 0
                                  ? AppColors.error
                                  : AppColors.textHint,
                      fontWeight: FontWeight.w600,
                    )),
              ),
            ),
            const SizedBox(height: 20),
            Text('Your Comment', style: AppTextStyles.h3),
            const SizedBox(height: 10),
            TextField(
              controller: _commentCtrl,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Share your experience...',
                hintStyle: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textHint),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: AppColors.cardBorder)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: AppColors.cardBorder)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 1.5)),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _rating == 0 || _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.cardBorder,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: _submitting
                    ? const CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2)
                    : Text(
                        widget.existing != null
                            ? 'Update Review'
                            : 'Submit Review',
                        style: AppTextStyles.labelLarge),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_rating == 0) return;
    setState(() => _submitting = true);
    final success = await context.read<ReviewCubit>().submitReview(
          rating: _rating,
          comment: _commentCtrl.text.trim(),
        );
    if (mounted) {
      setState(() => _submitting = false);
      if (success) Navigator.pop(context);
    }
  }

  String _ratingLabel(double r) {
    if (r == 0) return 'Tap a star to rate';
    if (r == 1) return '😞 Poor';
    if (r == 2) return '😐 Fair';
    if (r == 3) return '🙂 Good';
    if (r == 4) return '😊 Very Good';
    return '🤩 Excellent!';
  }
}

// ─────────────────────────────────────────────────────────────────
// Reusable: Star Row
// ─────────────────────────────────────────────────────────────────
class _StarRow extends StatelessWidget {
  final double rating;
  final double size;
  const _StarRow({required this.rating, required this.size});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final v = i + 1.0;
        final icon = rating >= v
            ? Icons.star_rounded
            : rating >= v - 0.5
                ? Icons.star_half_rounded
                : Icons.star_border_rounded;
        return Icon(icon, color: const Color(0xFFF59E0B), size: size);
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// ✅ Mini Rating Widget — للـ Course Cards في Home + Details
// استخدامه: CourseRatingMini(rating: course.rating, reviewCount: course.studentsCount)
// ─────────────────────────────────────────────────────────────────
class CourseRatingMini extends StatelessWidget {
  final double rating;
  final int reviewCount;
  const CourseRatingMini(
      {super.key, required this.rating, required this.reviewCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 16),
        const SizedBox(width: 3),
        Text(rating.toStringAsFixed(1),
            style: AppTextStyles.bodySmall
                .copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(width: 4),
        Text('($reviewCount)',
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}