import 'dart:async' as dart_async;
import 'dart:io';

import 'package:e_learning/core/erros/app_exceptions.dart';
import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/features/courses/data/model/courses.dart';
import 'package:e_learning/features/courses/data/repo/course_repo.dart';
import 'package:e_learning/features/quiz/data/model/quiz_model.dart';
import 'package:e_learning/features/quiz/data/repo/quiz_repo.dart';
import 'package:e_learning/features/quiz/presentation/view/quiz_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

// ─────────────────────────────────────────────────────────────────
// Video Error Type
// ─────────────────────────────────────────────────────────────────
enum _VideoErrorType { noInternet, timeout, unavailable, unknown }

bool _isYouTubeUrl(String url) =>
    url.contains('youtube.com') || url.contains('youtu.be');

String? _extractYouTubeId(String url) =>
    YoutubePlayer.convertUrlToId(url);

// ─────────────────────────────────────────────────────────────────
// VideoPlayerScreen
// ─────────────────────────────────────────────────────────────────
class VideoPlayerScreen extends StatefulWidget {
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
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  YoutubePlayerController? _ytCtrl;
  VideoPlayerController? _videoCtrl;
  ChewieController? _chewieCtrl;

  bool _isYoutube = false;
  bool _loading = true;
  _VideoErrorType? _errorType; // ✅ typed error بدل bool
  bool _markedWatched = false;

  QuizModel? _quiz;
  List<VideoModel> _upNextVideos = [];
  double _speed = 1.0;
  final _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  void initState() {
    super.initState();
    _initPlayer();
    _loadQuiz();
    _buildUpNext();
  }

  // ── Init ───────────────────────────────────────────────────────
  void _initPlayer() {
    final url = widget.video.videoUrl;
    _isYoutube = _isYouTubeUrl(url);

    if (_isYoutube) {
      final videoId = _extractYouTubeId(url);
      if (videoId == null) {
        setState(() {
          _errorType = _VideoErrorType.unavailable;
          _loading = false;
        });
        return;
      }
      _ytCtrl = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          enableCaption: false,
          forceHD: false,
        ),
      )..addListener(_onYouTubeProgress);
      setState(() => _loading = false);
    } else {
      _initDirectVideo(url);
    }
  }

  Future<void> _initDirectVideo(String url) async {
    try {
      _videoCtrl = VideoPlayerController.networkUrl(Uri.parse(url));

      // ✅ timeout على الـ initialize
      await _videoCtrl!.initialize().timeout(
        const Duration(seconds: 20),
        onTimeout: () => throw dart_async.TimeoutException('Video init timeout'),
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
        // ✅ Chewie errorBuilder للـ playback errors
        errorBuilder: (ctx, errorMessage) => _VideoErrorOverlay(
          errorType: _VideoErrorType.unknown,
          onRetry: () {
            setState(() {
              _errorType = null;
              _loading = true;
            });
            _initDirectVideo(url);
          },
        ),
      );

      _videoCtrl!.addListener(_onDirectVideoProgress);
      if (mounted) setState(() => _loading = false);

    } on dart_async.TimeoutException catch (_) {
      if (mounted) setState(() {
        _loading = false;
        _errorType = _VideoErrorType.timeout;
      });
    } on SocketException catch (_) {
      if (mounted) setState(() {
        _loading = false;
        _errorType = _VideoErrorType.noInternet;
      });
    } catch (e) {
      // ✅ check رسالة الـ error عشان نفرق بين network وغيره
      final msg = e.toString().toLowerCase();
      _VideoErrorType type;
      if (msg.contains('socket') ||
          msg.contains('network') ||
          msg.contains('host lookup') ||
          msg.contains('connection refused')) {
        type = _VideoErrorType.noInternet;
      } else if (msg.contains('404') ||
          msg.contains('not found') ||
          msg.contains('forbidden') ||
          msg.contains('403')) {
        type = _VideoErrorType.unavailable;
      } else {
        type = _VideoErrorType.unknown;
      }
      if (mounted) setState(() {
        _loading = false;
        _errorType = type;
      });
    }
  }

  // ── Progress listeners ─────────────────────────────────────────
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

  // ── Quiz ───────────────────────────────────────────────────────
  Future<void> _loadQuiz() async {
    try {
      final quiz = await QuizRepo().fetchQuizForVideo(widget.video.id);
      if (mounted) setState(() => _quiz = quiz);
    } catch (_) {
      // quiz load failure لا يمنع مشاهدة الفيديو
    }
  }

  void _buildUpNext() {
    if (widget.courseVideos == null) return;
    final currentIndex =
        widget.courseVideos!.indexWhere((v) => v.id == widget.video.id);
    final after = currentIndex >= 0
        ? widget.courseVideos!.sublist(currentIndex + 1)
        : <VideoModel>[];
    final before = currentIndex > 0
        ? widget.courseVideos!.sublist(0, currentIndex)
        : <VideoModel>[];
    setState(() => _upNextVideos = [...after, ...before]);
  }

  // ── Speed ──────────────────────────────────────────────────────
  void _setSpeed(double speed) {
    setState(() => _speed = speed);
    _ytCtrl?.setPlaybackRate(speed);
  }

  void _showSpeedSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(100)),
            ),
            const SizedBox(height: 16),
            Text('Playback Speed', style: AppTextStyles.h2),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _speeds.map((s) {
                final selected = s == _speed;
                return GestureDetector(
                  onTap: () {
                    _setSpeed(s);
                    Navigator.pop(context);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.cardBorder),
                    ),
                    child: Text(
                      '${s}x',
                      style: AppTextStyles.bodySmall.copyWith(
                          color:
                              selected ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _share() {
    Share.share(
      '🎓 Check out this lesson: ${widget.video.title}\n${widget.video.videoUrl}',
      subject: widget.video.title,
    );
  }

  // ── Quiz ───────────────────────────────────────────────────────
  void _openQuiz() {
    if (_quiz == null || _quiz!.questions.isEmpty) return;
    _ytCtrl?.pause();
    _videoCtrl?.pause();

    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    QuizRepo().fetchUserResult(userId, _quiz!.id).then((prev) {
      if (!mounted) return;
      if (prev != null) {
        _showPreviousResult(prev);
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => QuizScreen(quiz: _quiz!, onComplete: () {})),
        );
      }
    }).catchError((_) {
      // لو fetchUserResult فشل، افتح الـ quiz بدون check
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => QuizScreen(quiz: _quiz!, onComplete: () {})),
        );
      }
    });
  }

  void _showPreviousResult(QuizResult prev) {
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
              prev.passed
                  ? Icons.check_circle_rounded
                  : Icons.cancel_rounded,
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
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text('Cancel',
                      style: AppTextStyles.labelMedium
                          .copyWith(color: AppColors.textSecondary)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              QuizScreen(quiz: _quiz!, onComplete: () {})),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
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

  void _openVideo(VideoModel video) {
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

  @override
  Widget build(BuildContext context) {
    if (_isYoutube && _ytCtrl != null) {
      return YoutubePlayerBuilder(
        onEnterFullScreen: () => SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]),
        onExitFullScreen: () => SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]),
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
              child: Text(
                widget.video.title,
                style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GestureDetector(
              onTap: _showSpeedSheet,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_speed}x',
                  style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
        builder: (ctx, player) => _buildScaffold(ctx, player),
      );
    }

    return _buildScaffold(context, _buildDirectVideoPlayer());
  }

  // ── Scaffold ───────────────────────────────────────────────────
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
                      // Back + Title
                      Row(children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 38, height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 16,
                                color: AppColors.textPrimary),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(widget.video.title,
                              style: AppTextStyles.h2,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ]),
                      const SizedBox(height: 12),

                      // Duration + Watched badge + Speed + Share
                      Row(children: [
                        const Icon(Icons.schedule_outlined,
                            size: 15, color: AppColors.textHint),
                        const SizedBox(width: 6),
                        Text(widget.video.duration,
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textSecondary)),
                        if (_markedWatched) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Row(children: [
                              const Icon(Icons.check_circle_rounded,
                                  color: AppColors.success, size: 13),
                              const SizedBox(width: 4),
                              Text('Watched',
                                  style: AppTextStyles.caption.copyWith(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w600)),
                            ]),
                          ),
                        ],
                        const Spacer(),
                        if (_isYoutube)
                          GestureDetector(
                            onTap: _showSpeedSheet,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: AppColors.cardBorder),
                              ),
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.speed_rounded,
                                        size: 14,
                                        color: AppColors.textSecondary),
                                    const SizedBox(width: 4),
                                    Text('${_speed}x',
                                        style: AppTextStyles.caption.copyWith(
                                            fontWeight: FontWeight.w700)),
                                  ]),
                            ),
                          ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _share,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: AppColors.cardBorder),
                            ),
                            child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.share_outlined,
                                      size: 14,
                                      color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Text('Share',
                                      style: AppTextStyles.caption.copyWith(
                                          fontWeight: FontWeight.w600)),
                                ]),
                          ),
                        ),
                      ]),

                      // Quiz Card
                      if (_quiz != null && _quiz!.questions.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const Divider(color: AppColors.divider),
                        const SizedBox(height: 16),
                        Text('Lesson Quiz', style: AppTextStyles.h2),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: _openQuiz,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: AppColors.primary.withOpacity(0.2)),
                            ),
                            child: Row(children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.quiz_rounded,
                                    color: AppColors.primary, size: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_quiz!.title, style: AppTextStyles.h3),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${_quiz!.questions.length} questions  •  Pass: ${_quiz!.passScore}%',
                                      style: AppTextStyles.caption.copyWith(
                                          color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Text('Start',
                                    style: AppTextStyles.caption.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700)),
                              ),
                            ]),
                          ),
                        ),
                      ],

                      // Up Next
                      if (_upNextVideos.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Divider(color: AppColors.divider),
                        const SizedBox(height: 16),
                        Row(children: [
                          Text('Up Next', style: AppTextStyles.h2),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              '${_upNextVideos.length} videos',
                              style: AppTextStyles.caption.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 12),
                        ..._upNextVideos
                            .take(5)
                            .map((v) => _UpNextItem(
                                  video: v,
                                  isCurrent: false,
                                  onTap: () => _openVideo(v),
                                )),
                      ],
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

  // ── Direct Video Player Widget ─────────────────────────────────
  Widget _buildDirectVideoPlayer() {
    // Loading
    if (_loading) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: ColoredBox(
          color: Colors.black,
          child: Center(
              child: CircularProgressIndicator(color: AppColors.primary)),
        ),
      );
    }

    // ✅ Typed error with retry
    if (_errorType != null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: _VideoErrorOverlay(
          errorType: _errorType!,
          onRetry: () {
            setState(() {
              _errorType = null;
              _loading = true;
            });
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

// ─────────────────────────────────────────────────────────────────
// ✅ Video Error Overlay
// ─────────────────────────────────────────────────────────────────
class _VideoErrorOverlay extends StatelessWidget {
  final _VideoErrorType errorType;
  final VoidCallback? onRetry;

  const _VideoErrorOverlay({required this.errorType, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final config = _config(errorType);
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(config.icon, color: Colors.white60, size: 34),
              ),
              const SizedBox(height: 16),
              Text(
                config.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                config.subtitle,
                style: const TextStyle(
                  color: Colors.white54,
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null && errorType != _VideoErrorType.unavailable) ...[
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: onRetry,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 11),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh_rounded,
                            color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Try Again',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  _VideoErrorConfig _config(_VideoErrorType type) {
    switch (type) {
      case _VideoErrorType.noInternet:
        return _VideoErrorConfig(
          icon: Icons.wifi_off_rounded,
          title: 'No Internet Connection',
          subtitle:
              'Check your Wi-Fi or mobile data\nthen try again.',
        );
      case _VideoErrorType.timeout:
        return _VideoErrorConfig(
          icon: Icons.hourglass_disabled_rounded,
          title: 'Video Took Too Long',
          subtitle:
              'The video is taking too long to load.\nPlease try again.',
        );
      case _VideoErrorType.unavailable:
        return _VideoErrorConfig(
          icon: Icons.videocam_off_rounded,
          title: 'Video Unavailable',
          subtitle: 'This video is no longer available\nor has been removed.',
        );
      case _VideoErrorType.unknown:
        return _VideoErrorConfig(
          icon: Icons.error_outline_rounded,
          title: 'Failed to Load Video',
          subtitle:
              'Something went wrong while loading\nthis video. Please try again.',
        );
    }
  }
}

class _VideoErrorConfig {
  final IconData icon;
  final String title;
  final String subtitle;
  const _VideoErrorConfig(
      {required this.icon, required this.title, required this.subtitle});
}

// ─────────────────────────────────────────────────────────────────
// Up Next Item (unchanged)
// ─────────────────────────────────────────────────────────────────
class _UpNextItem extends StatelessWidget {
  final VideoModel video;
  final bool isCurrent;
  final VoidCallback onTap;

  const _UpNextItem({
    required this.video,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isCurrent
              ? AppColors.primary.withOpacity(0.06)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isCurrent
                  ? AppColors.primary.withOpacity(0.3)
                  : AppColors.cardBorder),
        ),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 90,
              height: 58,
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withOpacity(0.7),
                  AppColors.primary.withOpacity(0.4),
                ],
              )),
              child: Center(
                child: Icon(
                  isCurrent
                      ? Icons.pause_circle_rounded
                      : Icons.play_circle_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.title,
                  style: AppTextStyles.h3.copyWith(
                      color: isCurrent
                          ? AppColors.primary
                          : AppColors.textPrimary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.schedule_outlined,
                      size: 12, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(video.duration,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary)),
                  if (video.isLocked) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.lock_outline_rounded,
                        size: 12, color: AppColors.textHint),
                  ],
                ]),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textHint, size: 20),
        ]),
      ),
    );
  }
}