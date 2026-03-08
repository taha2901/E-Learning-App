import 'package:e_learning/core/erros/app_error_widget.dart';
import 'package:e_learning/core/erros/app_exceptions.dart';
import 'package:e_learning/core/erros/network_exception_handler.dart';
import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/features/courses/data/model/courses.dart';
import 'package:e_learning/features/quiz/data/model/quiz_model.dart';
import 'package:e_learning/features/quiz/data/repo/quiz_repo.dart';
import 'package:e_learning/features/quiz/presentation/view/quiz_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class VideoPlayerScreen extends StatefulWidget {
  final VideoModel video;
  final VoidCallback? onWatched;
  const VideoPlayerScreen({super.key, required this.video, this.onWatched});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _videoCtrl;
  ChewieController? _chewieCtrl;
  bool _loading = true;
  bool _error = false;
  String? _errorMessage;

  QuizModel? _quiz;
  bool _quizLoading = false;
  AppException? _quizError;

  bool _markedWatched = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
    _loadQuiz();
  }

  Future<void> _initVideo() async {
    setState(() {
      _loading = true;
      _error = false;
      _errorMessage = null;
    });
    try {
      _videoCtrl = VideoPlayerController.networkUrl(
          Uri.parse(widget.video.videoUrl));
      await _videoCtrl!.initialize();
      _chewieCtrl = ChewieController(
        videoPlayerController: _videoCtrl!,
        autoPlay: true,
        allowFullScreen: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primary,
          handleColor: AppColors.primary,
          backgroundColor: Colors.white24,
          bufferedColor: Colors.white38,
        ),
      );
      _videoCtrl!.addListener(_onProgress);
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = true;
          _errorMessage =
              NetworkExceptionHandler.handle(e).message;
        });
      }
    }
  }

  Future<void> _loadQuiz() async {
    setState(() {
      _quizLoading = true;
      _quizError = null;
    });
    try {
      final quiz = await QuizRepo().fetchQuizForVideo(widget.video.id);
      if (mounted) {
        setState(() {
          _quiz = quiz;
          _quizLoading = false;
        });
      }
    } on AppException catch (e) {
      if (mounted) {
        setState(() {
          _quizError = e;
          _quizLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _quizError = NetworkExceptionHandler.handle(e);
          _quizLoading = false;
        });
      }
    }
  }

  void _onProgress() {
    if (_videoCtrl == null) return;
    final pos = _videoCtrl!.value.position.inSeconds;
    final dur = _videoCtrl!.value.duration.inSeconds;
    if (dur == 0) return;

    if (!_markedWatched && pos / dur >= 0.9) {
      _markedWatched = true;
      widget.onWatched?.call();
    }
  }

  void _openQuiz() {
    if (_quiz == null || _quiz!.questions.isEmpty) return;
    _videoCtrl?.pause();

    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';

    QuizRepo().fetchUserResult(userId, _quiz!.id).then((prev) {
      if (!mounted) return;
      if (prev != null) {
        _showPreviousResult(prev);
      } else {
        _navigateToQuiz();
      }
    }).catchError((e) {
      // ✅ لو fetchUserResult فشل — افتح الـ quiz مباشرة
      if (mounted) _navigateToQuiz();
    });
  }

  void _navigateToQuiz() {
    if (_quiz == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizScreen(quiz: _quiz!, onComplete: () {}),
      ),
    );
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
                    _navigateToQuiz();
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

  @override
  void dispose() {
    _videoCtrl?.removeListener(_onProgress);
    _videoCtrl?.dispose();
    _chewieCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // ── Video Player ─────────────────────────────────────────────
            AspectRatio(
              aspectRatio: 16 / 9,
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary))
                  : _error
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  color: Colors.white54, size: 48),
                              const SizedBox(height: 12),
                              Text(
                                _errorMessage ?? 'Could not load video',
                                style: AppTextStyles.bodyMedium
                                    .copyWith(color: Colors.white54),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              // ✅ Retry زر في الـ video player
                              TextButton.icon(
                                onPressed: _initVideo,
                                icon: const Icon(Icons.refresh_rounded,
                                    color: Colors.white54),
                                label: const Text('Retry',
                                    style: TextStyle(color: Colors.white54)),
                              ),
                            ],
                          ),
                        )
                      : Chewie(controller: _chewieCtrl!),
            ),

            // ── Info ─────────────────────────────────────────────────────
            Expanded(
              child: Container(
                color: AppColors.background,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                            child: const Icon(Icons.arrow_back_ios_new_rounded,
                                size: 16, color: AppColors.textPrimary),
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
                      ]),

                      // ✅ Quiz Section — with loading / error / content states
                      const SizedBox(height: 20),
                      const Divider(color: AppColors.divider),
                      const SizedBox(height: 16),

                      if (_quizLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      else if (_quizError != null)
                        // ✅ Quiz load error — زغير مع retry
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.error.withOpacity(0.2)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.wifi_off_rounded,
                                color: AppColors.error, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _quizError!.message,
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: AppColors.error),
                              ),
                            ),
                            TextButton(
                              onPressed: _loadQuiz,
                              child: Text('Retry',
                                  style: AppTextStyles.caption.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ]),
                        )
                      else if (_quiz != null &&
                          _quiz!.questions.isNotEmpty) ...[
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
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(_quiz!.title,
                                        style: AppTextStyles.h3),
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
}