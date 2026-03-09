import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/features/courses/data/model/review_model.dart';
import 'package:e_learning/features/courses/presentation/cubit/review_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WriteReviewSheet extends StatefulWidget {
  final ReviewModel? existing;

  const WriteReviewSheet({super.key, this.existing});

  @override
  State<WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<WriteReviewSheet> {
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

  String _ratingLabel(double r) {
    if (r == 0) return 'Tap a star to rate';
    if (r == 1) return '😞 Poor';
    if (r == 2) return '😐 Fair';
    if (r == 3) return '🙂 Good';
    if (r == 4) return '😊 Very Good';
    return '🤩 Excellent!';
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
            // Handle
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

            // Title
            Row(
              children: [
                Text(
                  widget.existing != null ? 'Edit Review' : 'Write a Review',
                  style: AppTextStyles.h1,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Stars
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
                child: Text(
                  _ratingLabel(_rating),
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
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Comment
            Text('Your Comment', style: AppTextStyles.h3),
            const SizedBox(height: 10),
            TextField(
              controller: _commentCtrl,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Share your experience...',
                hintStyle:
                    AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
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

            // Submit
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
                        style: AppTextStyles.labelLarge,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}