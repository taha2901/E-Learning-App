import 'package:e_learning/core/erros/app_exceptions.dart';
import 'package:e_learning/core/erros/network_exception_handler.dart';
import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/features/admin_panel/add_courses/data/repo/admin_courses_repo.dart';
import 'package:e_learning/features/admin_panel/add_courses/presentation/view/widgets/add_video_sheet.dart';
import 'package:e_learning/features/admin_panel/add_courses/presentation/view/widgets/admin_back_button.dart';
import 'package:e_learning/features/admin_panel/add_courses/presentation/view/widgets/video_list_tile.dart';
import 'package:e_learning/features/courses/data/model/courses.dart';
import 'package:flutter/material.dart';

class ManageVideosScreen extends StatefulWidget {
  final CourseModel course;
  final AdminCoursesRepo repo;

  const ManageVideosScreen({
    super.key,
    required this.course,
    required this.repo,
  });

  @override
  State<ManageVideosScreen> createState() => _ManageVideosScreenState();
}

class _ManageVideosScreenState extends State<ManageVideosScreen> {
  late List<VideoModel> _videos;
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _videos = List.from(widget.course.videos);
  }

  // ── Add video (optimistic) ───────────────────────────────

  Future<void> _addVideo() async {
    if (_isAdding) return;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const AddVideoSheet(),
    );

    if (result == null || !mounted) return;

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempVideo = VideoModel(
      id: tempId,
      courseId: widget.course.id,
      title: result['title'],
      duration: result['duration'],
      videoUrl: result['video_url'],
      isLocked: result['is_locked'],
      isWatched: false,
    );

    setState(() { _videos = [..._videos, tempVideo]; _isAdding = true; });

    try {
      final id = await widget.repo.addVideo(
        courseId: widget.course.id,
        title: result['title'],
        duration: result['duration'],
        videoUrl: result['video_url'],
        isLocked: result['is_locked'],
      );

      if (mounted && id != null) {
        setState(() {
          _videos = _videos.map((v) => v.id == tempId
              ? VideoModel(
                  id: id,
                  courseId: widget.course.id,
                  title: result['title'],
                  duration: result['duration'],
                  videoUrl: result['video_url'],
                  isLocked: result['is_locked'],
                  isWatched: false,
                )
              : v).toList();
        });
        _showSnack('Video added!');
      }
    } on AppException catch (e) {
      if (mounted) {
        setState(() =>
            _videos = _videos.where((v) => v.id != tempId).toList());
        _showSnack(e.message, isError: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() =>
            _videos = _videos.where((v) => v.id != tempId).toList());
        _showSnack(NetworkExceptionHandler.handle(e).message,
            isError: true);
      }
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  // ── Delete video (optimistic rollback) ──────────────────

  Future<void> _deleteVideo(VideoModel video) async {
    setState(() =>
        _videos = _videos.where((v) => v.id != video.id).toList());
    try {
      await widget.repo.deleteVideo(video.id, widget.course.id);
    } on AppException catch (e) {
      if (mounted) {
        setState(() => _videos = [..._videos, video]);
        _showSnack(e.message, isError: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _videos = [..._videos, video]);
        _showSnack(NetworkExceptionHandler.handle(e).message,
            isError: true);
      }
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Build ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const AdminBackButton(),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Videos', style: AppTextStyles.h2),
            Text(
              widget.course.title,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: _isAdding ? null : _addVideo,
              child: _AddButton(isAdding: _isAdding),
            ),
          ),
        ],
      ),
      body: _videos.isEmpty
          ? const _EmptyVideosState()
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _videos.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final video = _videos[i];
                return VideoListTile(
                  video: video,
                  onDelete: () =>
                      _confirmDeleteVideo(context, video),
                );
              },
            ),
    );
  }

  void _confirmDeleteVideo(BuildContext context, VideoModel video) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Video?', style: AppTextStyles.h2),
        content: Text('Delete "${video.title}"?',
            style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () { Navigator.pop(ctx); _deleteVideo(video); },
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
// Add button in app bar
// ─────────────────────────────────────────────
class _AddButton extends StatelessWidget {
  final bool isAdding;
  const _AddButton({required this.isAdding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isAdding
            ? AppColors.primary.withOpacity(0.5)
            : AppColors.primary,
        borderRadius: BorderRadius.circular(100),
      ),
      child: isAdding
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2),
            )
          : Row(
              children: [
                const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 4),
                Text('Add',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    )),
              ],
            ),
    );
  }
}

// ─────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────
class _EmptyVideosState extends StatelessWidget {
  const _EmptyVideosState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.video_library_outlined,
              size: 56, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text('No videos yet', style: AppTextStyles.h2),
          const SizedBox(height: 8),
          Text(
            'Tap "Add" to add lessons',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}