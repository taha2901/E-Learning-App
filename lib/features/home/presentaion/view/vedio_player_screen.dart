import 'dart:async' as dart_async;
import 'dart:io';

import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/features/courses/data/model/courses.dart';
import 'package:e_learning/features/courses/data/repo/course_repo.dart';
import 'package:e_learning/features/home/presentaion/cubit/video_player_cubit.dart';
import 'package:e_learning/features/home/presentaion/cubit/video_player_states.dart';
import 'package:e_learning/features/home/presentaion/view/widgets/video_player/video_error_overlay.dart';
import 'package:e_learning/features/home/presentaion/view/widgets/video_player/video_info_bar.dart';
import 'package:e_learning/features/home/presentaion/view/widgets/video_player/video_quiz_card.dart';
import 'package:e_learning/features/home/presentaion/view/widgets/video_player/video_speed_sheet.dart';
import 'package:e_learning/features/home/presentaion/view/widgets/video_player/video_up_next_section.dart';
import 'package:e_learning/features/quiz/data/model/quiz_model.dart';
import 'package:e_learning/features/quiz/data/repo/quiz_repo.dart';
import 'package:e_learning/features/quiz/presentation/view/quiz_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

bool _isYouTubeUrl(String url) =>
    url.contains('youtube.com') || url.contains('youtu.be');

String? _extractYouTubeId(String url) => YoutubePlayer.convertUrlToId(url);

// ─────────────────────────────────────────────
// VideoPlayerScreen — entry point
// بتعمل BlocProvider للـ VideoPlayerCubit وتبدأ تحميل الكويز فوراً
// ─────────────────────────────────────────────
class VideoPlayerScreen extends StatelessWidget {
  final VideoModel video;
  final List<VideoModel>? courseVideos;
  final VoidCallback? onWatched;

  const VideoPlayerScreen({
    super.key,
    required this.video,
    this.courseVideos,
    this.onWatched,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VideoPlayerCubit(QuizRepo())..loadQuizForVideo(video.id),
      child: _VideoPlayerBody(video: video, courseVideos: courseVideos, onWatched: onWatched),
    );
  }
}

// ─────────────────────────────────────────────
// _VideoPlayerBody — كل الـ logic هنا
// ─────────────────────────────────────────────
class _VideoPlayerBody extends StatefulWidget {
  final VideoModel video;
  final List<VideoModel>? courseVideos;
  final VoidCallback? onWatched;

  const _VideoPlayerBody({
    required this.video,
    this.courseVideos,
    this.onWatched,
  });

  @override
  State<_VideoPlayerBody> createState() => _VideoPlayerBodyState();
}

class _VideoPlayerBodyState extends State<_VideoPlayerBody> {
  YoutubePlayerController? _ytCtrl;
  VideoPlayerController? _videoCtrl;
  ChewieController? _chewieCtrl;

  bool _isYoutube = false;
  bool _loading = true;
  VideoErrorType? _errorType;
  bool _markedWatched = false;

  List<VideoModel> _upNextVideos = [];
  double _speed = 1.0;
  final _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  void initState() {
    super.initState();
    _initPlayer();
    _buildUpNext();
  }

  // ── Video Player Init ─────────────────────────────────────────────────────

  void _initPlayer() {
    final url = widget.video.videoUrl;
    _isYoutube = _isYouTubeUrl(url);

    if (_isYoutube) {
      final videoId = _extractYouTubeId(url);
      if (videoId == null) {
        setState(() { _errorType = VideoErrorType.unavailable; _loading = false; });
        return;
      }
      _ytCtrl = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(autoPlay: true, mute: false, enableCaption: false),
      )..addListener(_onYouTubeProgress);
      setState(() => _loading = false);
    } else {
      _initDirectVideo(url);
    }
  }

  Future<void> _initDirectVideo(String url) async {
    try {
      _videoCtrl = VideoPlayerController.networkUrl(Uri.parse(url));
      await _videoCtrl!.initialize().timeout(
        const Duration(seconds: 20),
        onTimeout: () => throw dart_async.TimeoutException('timeout'),
      );
      _chewieCtrl = ChewieController(
        videoPlayerController: _videoCtrl!,
        autoPlay: true,
        allowFullScreen: true,
        allowPlaybackSpeedChanging: true,
        playbackSpeeds: _speeds,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primary,
          handleColor: AppColors.primary,
          backgroundColor: Colors.white24,
          bufferedColor: Colors.white38,
        ),
        errorBuilder: (ctx, _) => VideoErrorOverlay(
          errorType: VideoErrorType.unknown,
          onRetry: () {
            setState(() { _errorType = null; _loading = true; });
            _initDirectVideo(url);
          },
        ),
      );
      _videoCtrl!.addListener(_onDirectVideoProgress);
      if (mounted) setState(() => _loading = false);
    } on dart_async.TimeoutException {
      if (mounted) setState(() { _loading = false; _errorType = VideoErrorType.timeout; });
    } on SocketException {
      if (mounted) setState(() { _loading = false; _errorType = VideoErrorType.noInternet; });
    } catch (e) {
      final msg = e.toString().toLowerCase();
      VideoErrorType type;
      if (msg.contains('socket') || msg.contains('network') || msg.contains('host lookup')) {
        type = VideoErrorType.noInternet;
      } else if (msg.contains('404') || msg.contains('not found') || msg.contains('403')) {
        type = VideoErrorType.unavailable;
      } else {
        type = VideoErrorType.unknown;
      }
      if (mounted) setState(() { _loading = false; _errorType = type; });
    }
  }

  // ── Progress Listeners ────────────────────────────────────────────────────

  void _onYouTubeProgress() {
    if (_ytCtrl == null) return;
    final pos = _ytCtrl!.value.position.inSeconds;
    final dur = _ytCtrl!.metadata.duration.inSeconds;
    if (dur == 0) return;
    if (!_markedWatched && pos / dur >= 0.9) {
      _markedWatched = true;
      widget.onWatched?.call();
      if (mounted) setState(() {});
    }
  }

  void _onDirectVideoProgress() {
    if (_videoCtrl == null) return;
    final pos = _videoCtrl!.value.position.inSeconds;
    final dur = _videoCtrl!.value.duration.inSeconds;
    if (dur == 0) return;
    if (!_markedWatched && pos / dur >= 0.9) {
      _markedWatched = true;
      widget.onWatched?.call();
      if (mounted) setState(() {});
    }
  }

  // ── Up Next ───────────────────────────────────────────────────────────────

  void _buildUpNext() {
    if (widget.courseVideos == null) return;
    final idx = widget.courseVideos!.indexWhere((v) => v.id == widget.video.id);
    final after = idx >= 0 ? widget.courseVideos!.sublist(idx + 1) : <VideoModel>[];
    final before = idx > 0 ? widget.courseVideos!.sublist(0, idx) : <VideoModel>[];
    setState(() => _upNextVideos = [...after, ...before]);
  }

  // ── Quiz Actions — بيجيب البيانات من الـ Cubit state مش من الـ repo ──────

  void _openQuiz(QuizModel quiz, QuizResult? previousResult) {
    if (quiz.questions.isEmpty) return;
    _ytCtrl?.pause();
    _videoCtrl?.pause();

    if (previousResult != null) {
      _showPreviousResultSheet(previousResult, quiz);
    } else {
      _navigateToQuiz(quiz);
    }
  }

  void _navigateToQuiz(QuizModel quiz) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizScreen(quiz: quiz, onComplete: () {}),
      ),
    );
  }

  void _showPreviousResultSheet(QuizResult prev, QuizModel quiz) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(100)),
            ),
            const SizedBox(height: 20),
            Icon(
              prev.passed ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: prev.passed ? AppColors.success : AppColors.error,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text('You already took this quiz', style: AppTextStyles.h2),
            const SizedBox(height: 8),
            Text(
              'Score: ${prev.percentage}% — ${prev.passed ? "Passed ✅" : "Failed ❌"}',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.cardBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text('Cancel',
                      style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () { Navigator.pop(ctx); _navigateToQuiz(quiz); },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text('Retake', style: AppTextStyles.labelMedium),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  // ── Navigate to next video ────────────────────────────────────────────────

  void _navigateToVideo(VideoModel video) {
    _ytCtrl?.pause();
    _videoCtrl?.pause();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(
          video: video,
          courseVideos: widget.courseVideos,
          onWatched: () async {
            await CoursesRepo().markVideoWatched(
              Supabase.instance.client.auth.currentUser?.id ?? '',
              video.id,
            );
          },
        ),
      ),
    );
  }

  void _setSpeed(double speed) {
    setState(() => _speed = speed);
    _ytCtrl?.setPlaybackRate(speed);
  }

  void _share() {
    Share.share(
      '🎓 Check out this lesson: ${widget.video.title}\n${widget.video.videoUrl}',
      subject: widget.video.title,
    );
  }

  @override
  void dispose() {
    _ytCtrl?.removeListener(_onYouTubeProgress);
    _ytCtrl?.dispose();
    _videoCtrl?.removeListener(_onDirectVideoProgress);
    _videoCtrl?.dispose();
    _chewieCtrl?.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isYoutube && _ytCtrl != null) {
      return YoutubePlayerBuilder(
        onEnterFullScreen: () => SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight,
        ]),
        onExitFullScreen: () =>
            SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
        player: YoutubePlayer(
          controller: _ytCtrl!,
          showVideoProgressIndicator: true,
          progressIndicatorColor: AppColors.primary,
          progressColors: ProgressBarColors(
            playedColor: AppColors.primary,
            handleColor: AppColors.primary,
            bufferedColor: AppColors.primary.withOpacity(0.3),
            backgroundColor: Colors.white24,
          ),
          topActions: [
            const SizedBox(width: 8),
            Expanded(
              child: Text(widget.video.title,
                  style: const TextStyle(color: Colors.white, fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w500),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            GestureDetector(
              onTap: () => VideoSpeedSheet.show(context, currentSpeed: _speed, speeds: _speeds, onSpeedSelected: _setSpeed),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(6)),
                child: Text('${_speed}x',
                    style: const TextStyle(color: Colors.white, fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
        builder: (ctx, player) => _buildScaffold(ctx, player),
      );
    }

    return _buildScaffold(context, _buildDirectVideoPlayer());
  }

  Widget _buildScaffold(BuildContext context, Widget videoWidget) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            videoWidget,
            Expanded(
              child: Container(
                color: AppColors.background,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      VideoInfoBar(
                        title: widget.video.title,
                        duration: widget.video.duration,
                        isWatched: _markedWatched,
                        showSpeedButton: _isYoutube,
                        currentSpeed: _speed,
                        onBack: () => Navigator.pop(context),
                        onSpeedTap: () => VideoSpeedSheet.show(context, currentSpeed: _speed, speeds: _speeds, onSpeedSelected: _setSpeed),
                        onShare: _share,
                      ),

                      // ── Quiz Section — من الـ Cubit مش من الـ Repo ──────
                      _buildQuizSection(),

                      VideoUpNextSection(
                        videos: _upNextVideos,
                        onVideoTap: _navigateToVideo,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// بيقرأ الـ state من VideoPlayerCubit ويعرض الكويز بناءً عليه
  Widget _buildQuizSection() {
    return BlocBuilder<VideoPlayerCubit, VideoPlayerState>(
      builder: (context, state) {
        // جاري تحميل
        if (state is VideoQuizLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        // حصل error — بنعرض error صغير مع retry
        if (state is VideoQuizError) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withOpacity(0.2)),
              ),
              child: Row(children: [
                const Icon(Icons.wifi_off_rounded, color: AppColors.error, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(state.exception.message,
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
                ),
                TextButton(
                  onPressed: () => context
                      .read<VideoPlayerCubit>()
                      .loadQuizForVideo(widget.video.id),
                  child: Text('Retry',
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary, fontWeight: FontWeight.w700)),
                ),
              ]),
            ),
          );
        }

        // اتحمل — لو في كويز وفيه أسئلة نعرضه
        if (state is VideoQuizLoaded &&
            state.quiz != null &&
            state.quiz!.questions.isNotEmpty) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: VideoQuizCard(
              quiz: state.quiz!,
              onTap: () => _openQuiz(state.quiz!, state.previousResult),
            ),
          );
        }

        // مفيش كويز للفيديو ده
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildDirectVideoPlayer() {
    if (_loading) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: ColoredBox(
            color: Colors.black,
            child: Center(child: CircularProgressIndicator(color: AppColors.primary))),
      );
    }
    if (_errorType != null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: VideoErrorOverlay(
          errorType: _errorType!,
          onRetry: () {
            setState(() { _errorType = null; _loading = true; });
            _initDirectVideo(widget.video.videoUrl);
          },
        ),
      );
    }
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Chewie(controller: _chewieCtrl!),
    );
  }
}
