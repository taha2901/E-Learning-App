// widgets/video_list_tile.dart

import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/features/courses/data/model/courses.dart';
import 'package:flutter/material.dart';

class VideoListTile extends StatelessWidget {
  final VideoModel video;
  final VoidCallback onDelete;

  const VideoListTile({
    super.key,
    required this.video,
    required this.onDelete,
  });

  bool get _isTemp => video.id.startsWith('temp_');

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _isTemp ? 0.6 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isTemp
                ? AppColors.primary.withOpacity(0.3)
                : AppColors.cardBorder,
          ),
        ),
        child: Row(
          children: [
            _VideoIcon(video: video, isTemp: _isTemp),
            const SizedBox(width: 12),
            Expanded(child: _VideoInfo(video: video)),
            if (!_isTemp) _DeleteButton(onTap: onDelete),
          ],
        ),
      ),
    );
  }
}

class _VideoIcon extends StatelessWidget {
  final VideoModel video;
  final bool isTemp;
  const _VideoIcon({required this.video, required this.isTemp});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: video.isLocked
            ? AppColors.error.withOpacity(0.1)
            : AppColors.success.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: isTemp
          ? const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primary),
              ),
            )
          : Icon(
              video.isLocked
                  ? Icons.lock_outline_rounded
                  : Icons.play_arrow_rounded,
              color: video.isLocked ? AppColors.error : AppColors.success,
              size: 20,
            ),
    );
  }
}

class _VideoInfo extends StatelessWidget {
  final VideoModel video;
  const _VideoInfo({required this.video});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(video.title,
            style: AppTextStyles.h3,
            maxLines: 2,
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.schedule_outlined,
                size: 12, color: AppColors.textHint),
            const SizedBox(width: 4),
            Text(video.duration, style: AppTextStyles.caption),
            if (video.isLocked) ...[
              const SizedBox(width: 8),
              _LockedBadge(),
            ],
          ],
        ),
      ],
    );
  }
}

class _LockedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        'Locked',
        style: AppTextStyles.caption.copyWith(
          color: AppColors.error,
          fontSize: 10,
        ),
      ),
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
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppColors.error, size: 16),
      ),
    );
  }
}