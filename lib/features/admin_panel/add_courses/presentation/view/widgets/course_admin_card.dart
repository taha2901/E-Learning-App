// widgets/course_admin_card.dart

import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/features/courses/data/model/courses.dart';
import 'package:flutter/material.dart';

class CourseAdminCard extends StatelessWidget {
  final CourseModel course;
  final VoidCallback onEdit;
  final VoidCallback onManageVideos;
  final VoidCallback onDelete;

  const CourseAdminCard({
    super.key,
    required this.course,
    required this.onEdit,
    required this.onManageVideos,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _CardThumbnail(course: course),
          _CardBody(
            course: course,
            onEdit: onEdit,
            onManageVideos: onManageVideos,
            onDelete: () => _confirmDelete(context),
          ),
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
        title: Text('Delete Course?', style: AppTextStyles.h2),
        content: Text(
          'This will delete "${course.title}" and all its videos. This cannot be undone.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () { Navigator.pop(ctx); onDelete(); },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Thumbnail with optional Featured badge
// ─────────────────────────────────────────────
class _CardThumbnail extends StatelessWidget {
  final CourseModel course;
  const _CardThumbnail({required this.course});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      child: Stack(
        children: [
          course.thumbnailUrl.isNotEmpty
              ? Image.network(
                  course.thumbnailUrl,
                  height: 130,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const _PlaceholderThumb(),
                )
              : const _PlaceholderThumb(),
          if (course.isFeatured)
            Positioned(
              top: 10,
              right: 10,
              child: _FeaturedBadge(),
            ),
        ],
      ),
    );
  }
}

class _PlaceholderThumb extends StatelessWidget {
  const _PlaceholderThumb();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130,
      width: double.infinity,
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: const Center(
        child: Icon(Icons.school_outlined, color: Colors.white, size: 48),
      ),
    );
  }
}

class _FeaturedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.warning,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text('Featured',
              style: AppTextStyles.caption.copyWith(color: Colors.white)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Card body (pills + title + stats + actions)
// ─────────────────────────────────────────────
class _CardBody extends StatelessWidget {
  final CourseModel course;
  final VoidCallback onEdit;
  final VoidCallback onManageVideos;
  final VoidCallback onDelete;

  const _CardBody({
    required this.course,
    required this.onEdit,
    required this.onManageVideos,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AdminPill(
                label: course.category,
                color: AppColors.primary.withOpacity(0.1),
                textColor: AppColors.primary,
              ),
              const SizedBox(width: 6),
              AdminPill(
                label: course.level,
                color: AppColors.surfaceVariant,
                textColor: AppColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(course.title, style: AppTextStyles.h3),
          const SizedBox(height: 2),
          Text(course.instructor,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          Row(
            children: [
              AdminStatChip(
                  icon: Icons.play_circle_outline_rounded,
                  label: '${course.videos.length} videos'),
              const SizedBox(width: 12),
              AdminStatChip(
                  icon: Icons.schedule_outlined, label: course.duration),
              const SizedBox(width: 12),
              AdminStatChip(
                  icon: Icons.star_rounded,
                  label: course.rating.toStringAsFixed(1)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),
          _ActionRow(
            course: course,
            onEdit: onEdit,
            onManageVideos: onManageVideos,
            onDelete: onDelete,
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final CourseModel course;
  final VoidCallback onEdit;
  final VoidCallback onManageVideos;
  final VoidCallback onDelete;

  const _ActionRow({
    required this.course,
    required this.onEdit,
    required this.onManageVideos,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AdminCardBtn(
            icon: Icons.edit_rounded,
            label: 'Edit',
            color: AppColors.primary,
            onTap: onEdit,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AdminCardBtn(
            icon: Icons.video_library_rounded,
            label: 'Videos (${course.videos.length})',
            color: AppColors.success,
            onTap: onManageVideos,
          ),
        ),
        const SizedBox(width: 8),
        _DeleteButton(onTap: onDelete),
      ],
    );
  }
}

class _DeleteButton extends StatelessWidget {
  final VoidCallback onTap;
  const _DeleteButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppColors.error, size: 18),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Shared small widgets (pill, stat chip, card btn)
// ─────────────────────────────────────────────
class AdminPill extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const AdminPill({
    super.key,
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: textColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class AdminStatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const AdminStatChip({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textHint),
        const SizedBox(width: 4),
        Text(label,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}

class AdminCardBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const AdminCardBtn({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}