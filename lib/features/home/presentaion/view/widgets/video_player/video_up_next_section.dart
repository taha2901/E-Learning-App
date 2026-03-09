import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/features/courses/data/model/courses.dart';
import 'package:e_learning/features/home/presentaion/view/widgets/video_player/video_up_next_item.dart';
import 'package:flutter/material.dart';

class VideoUpNextSection extends StatelessWidget {
  final List<VideoModel> videos;
  final ValueChanged<VideoModel> onVideoTap;

  const VideoUpNextSection({
    super.key,
    required this.videos,
    required this.onVideoTap,
  });

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Divider(color: AppColors.divider),
        const SizedBox(height: 16),
        Row(
          children: [
            Text('Up Next', style: AppTextStyles.h2),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                '${videos.length} videos',
                style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...videos.take(5).map(
              (v) => VideoUpNextItem(
                video: v,
                isCurrent: false,
                onTap: () => onVideoTap(v),
              ),
            ),
      ],
    );
  }
}