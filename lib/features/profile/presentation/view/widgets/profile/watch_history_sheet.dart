// sheets/watch_history_sheet.dart

import 'package:e_learning/core/erros/app_error_widget.dart';
import 'package:e_learning/core/erros/app_exceptions.dart';
import 'package:e_learning/core/erros/network_exception_handler.dart';
import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WatchHistorySheet extends StatefulWidget {
  final String userId;
  const WatchHistorySheet({super.key, required this.userId});

  @override
  State<WatchHistorySheet> createState() => _WatchHistorySheetState();
}

class _WatchHistorySheetState extends State<WatchHistorySheet> {
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;
  AppException? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await Supabase.instance.client
          .from('video_progress')
          .select(
            'video_id, watched_at, videos(title, duration, courses(title))',
          )
          .eq('user_id', widget.userId)
          .eq('watched', true)
          .order('watched_at', ascending: false)
          .limit(20);

      setState(() {
        _history = (result as List).cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = NetworkExceptionHandler.handle(e);
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (ctx, scrollCtrl) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: Column(
          children: [
            Row(
              children: [
                Text('Watch History', style: AppTextStyles.h2),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildBody(scrollCtrl)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ScrollController scrollCtrl) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return AppErrorWidget(exception: _error!, onRetry: _load);
    }
    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history_rounded,
                size: 56, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text(
              'No watch history yet',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      controller: scrollCtrl,
      itemCount: _history.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: AppColors.divider),
      itemBuilder: (_, i) => _HistoryTile(item: _history[i]),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final Map<String, dynamic> item;
  const _HistoryTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final video    = item['videos'] as Map<String, dynamic>? ?? {};
    final course   = video['courses'] as Map<String, dynamic>? ?? {};
    final watchedAt = DateTime.tryParse(item['watched_at'] ?? '') ?? DateTime.now();
    final diff     = DateTime.now().difference(watchedAt);
    final timeAgo  = diff.inDays > 0
        ? '${diff.inDays}d ago'
        : diff.inHours > 0
            ? '${diff.inHours}h ago'
            : 'Recently';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.play_circle_outline_rounded,
            color: AppColors.primary),
      ),
      title: Text(
        video['title'] ?? 'Unknown video',
        style: AppTextStyles.h3,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${course['title'] ?? ''} • ${video['duration'] ?? ''}',
        style: AppTextStyles.caption,
      ),
      trailing: Text(
        timeAgo,
        style: AppTextStyles.caption
            .copyWith(color: AppColors.textHint),
      ),
    );
  }
}