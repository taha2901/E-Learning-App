// import 'package:e_learning/core/constants/app_constants.dart';
// import 'package:e_learning/core/theme/app_colors.dart';
// import 'package:e_learning/core/theme/text_styles.dart';
// import 'package:e_learning/features/courses/data/model/courses.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';

// class VideoPlayerScreen extends StatefulWidget {
//   final VideoModel video;
//   const VideoPlayerScreen({super.key, required this.video});

//   @override
//   State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
// }

// class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
//   bool _isPlaying = false;
//   bool _showControls = true;
//   double _progress = 0.0;

//   @override
//   void initState() {
//     super.initState();
//     SystemChrome.setPreferredOrientations([
//       DeviceOrientation.landscapeLeft,
//       DeviceOrientation.landscapeRight,
//       DeviceOrientation.portraitUp,
//     ]);
//   }

//   @override
//   void dispose() {
//     SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
//     super.dispose();
//   }

//   String _formatTime(double seconds) {
//     final mins = (seconds ~/ 60).toString().padLeft(2, '0');
//     final secs = (seconds.toInt() % 60).toString().padLeft(2, '0');
//     return '$mins:$secs';
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: SafeArea(
//         child: Column(
//           children: [
//             GestureDetector(
//               onTap: () => setState(() => _showControls = !_showControls),
//               child: AspectRatio(
//                 aspectRatio: 16 / 9,
//                 child: Container(
//                   color: Colors.black,
//                   child: Stack(
//                     children: [
//                       Center(
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Icon(Icons.play_circle_fill_rounded,
//                                 color: Colors.white.withOpacity(0.12), size: 80),
//                             const SizedBox(height: 8),
//                             Padding(
//                               padding: const EdgeInsets.symmetric(horizontal: 24),
//                               child: Text(widget.video.title,
//                                   style: const TextStyle(
//                                       color: Colors.white24,
//                                       fontFamily: 'Poppins',
//                                       fontSize: 12),
//                                   textAlign: TextAlign.center),
//                             ),
//                           ],
//                         ),
//                       ),
//                       if (_showControls) ...[
//                         Positioned(
//                           top: 0, left: 0, right: 0,
//                           child: Container(
//                             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                             decoration: BoxDecoration(
//                               gradient: LinearGradient(
//                                 begin: Alignment.topCenter,
//                                 end: Alignment.bottomCenter,
//                                 colors: [Colors.black.withOpacity(0.7), Colors.transparent],
//                               ),
//                             ),
//                             child: Row(
//                               children: [
//                                 IconButton(
//                                   icon: const Icon(Icons.arrow_back_ios_new_rounded,
//                                       color: Colors.white, size: 18),
//                                   onPressed: () => Navigator.pop(context),
//                                 ),
//                                 Expanded(
//                                   child: Text(widget.video.title,
//                                       style: const TextStyle(
//                                           color: Colors.white, fontFamily: 'Poppins',
//                                           fontSize: 13, fontWeight: FontWeight.w500),
//                                       maxLines: 1, overflow: TextOverflow.ellipsis),
//                                 ),
//                                 IconButton(
//                                   icon: const Icon(Icons.settings_outlined,
//                                       color: Colors.white, size: 20),
//                                   onPressed: () {},
//                                 ),
//                                 IconButton(
//                                   icon: const Icon(Icons.fullscreen_rounded,
//                                       color: Colors.white, size: 22),
//                                   onPressed: () {},
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                         Center(
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               GestureDetector(
//                                 onTap: () {},
//                                 child: const Icon(Icons.replay_10_rounded,
//                                     color: Colors.white, size: 34),
//                               ),
//                               const SizedBox(width: 24),
//                               GestureDetector(
//                                 onTap: () => setState(() => _isPlaying = !_isPlaying),
//                                 child: Container(
//                                   width: 60, height: 60,
//                                   decoration: const BoxDecoration(
//                                       color: Colors.white, shape: BoxShape.circle),
//                                   child: Icon(
//                                     _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
//                                     color: AppColors.primary, size: 34,
//                                   ),
//                                 ),
//                               ),
//                               const SizedBox(width: 24),
//                               GestureDetector(
//                                 onTap: () {},
//                                 child: const Icon(Icons.forward_10_rounded,
//                                     color: Colors.white, size: 34),
//                               ),
//                             ],
//                           ),
//                         ),
//                         Positioned(
//                           bottom: 0, left: 0, right: 0,
//                           child: Container(
//                             padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
//                             decoration: BoxDecoration(
//                               gradient: LinearGradient(
//                                 begin: Alignment.bottomCenter,
//                                 end: Alignment.topCenter,
//                                 colors: [Colors.black.withOpacity(0.7), Colors.transparent],
//                               ),
//                             ),
//                             child: Column(
//                               children: [
//                                 Slider(
//                                   value: _progress,
//                                   onChanged: (v) => setState(() => _progress = v),
//                                   activeColor: AppColors.accent,
//                                   inactiveColor: Colors.white24,
//                                   thumbColor: Colors.white,
//                                 ),
//                                 Padding(
//                                   padding: const EdgeInsets.symmetric(horizontal: 12),
//                                   child: Row(
//                                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                     children: [
//                                       Text(_formatTime(_progress * 330),
//                                           style: const TextStyle(color: Colors.white70,
//                                               fontSize: 11, fontFamily: 'Poppins')),
//                                       Text(widget.video.duration,
//                                           style: const TextStyle(color: Colors.white70,
//                                               fontSize: 11, fontFamily: 'Poppins')),
//                                     ],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ],
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//             Expanded(
//               child: Container(
//                 color: AppColors.background,
//                 child: SingleChildScrollView(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Padding(
//                         padding: const EdgeInsets.all(AppConstants.horizontalPadding),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(widget.video.title, style: AppTextStyles.h2),
//                             const SizedBox(height: 6),
//                             Row(
//                               children: [
//                                 const Icon(Icons.schedule_outlined,
//                                     size: 14, color: AppColors.textHint),
//                                 const SizedBox(width: 4),
//                                 Text(widget.video.duration, style: AppTextStyles.bodySmall),
//                                 const SizedBox(width: 16),
//                                 const Icon(Icons.visibility_outlined,
//                                     size: 14, color: AppColors.textHint),
//                                 const SizedBox(width: 4),
//                                 Text('1.2k views', style: AppTextStyles.bodySmall),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                       const Divider(color: AppColors.divider, height: 1),
//                       Padding(
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: AppConstants.horizontalPadding, vertical: 12),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceAround,
//                           children: const [
//                             _ActionButton(icon: Icons.thumb_up_alt_outlined, label: 'Like'),
//                             _ActionButton(icon: Icons.share_outlined, label: 'Share'),
//                             _ActionButton(icon: Icons.download_outlined, label: 'Download'),
//                             _ActionButton(icon: Icons.bookmark_border_rounded, label: 'Save'),
//                           ],
//                         ),
//                       ),
//                       const Divider(color: AppColors.divider, height: 1),
//                       Padding(
//                         padding: const EdgeInsets.fromLTRB(
//                             AppConstants.horizontalPadding, 20,
//                             AppConstants.horizontalPadding, 12),
//                         child: Text('Up Next', style: AppTextStyles.h2),
//                       ),
//                       ...List.generate(3, (i) => _RelatedVideoItem(
//                           index: i + 1, title: widget.video.title)),
//                       const SizedBox(height: 20),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _ActionButton extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   const _ActionButton({required this.icon, required this.label});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Icon(icon, color: AppColors.textSecondary, size: 24),
//         const SizedBox(height: 4),
//         Text(label, style: AppTextStyles.caption),
//       ],
//     );
//   }
// }

// class _RelatedVideoItem extends StatelessWidget {
//   final int index;
//   final String title;
//   const _RelatedVideoItem({required this.index, required this.title});

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(
//           AppConstants.horizontalPadding, 0, AppConstants.horizontalPadding, 14),
//       child: Row(
//         children: [
//           ClipRRect(
//             borderRadius: BorderRadius.circular(AppConstants.radiusM),
//             child: Container(
//               width: 100, height: 64,
//               color: AppColors.primary.withOpacity(0.08),
//               child: const Center(
//                 child: Icon(Icons.play_circle_outline_rounded,
//                     color: AppColors.primary, size: 28),
//               ),
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text('Lesson ${index + 2}: $title',
//                     style: AppTextStyles.h3,
//                     maxLines: 2, overflow: TextOverflow.ellipsis),
//                 const SizedBox(height: 4),
//                 Text('8:45', style: AppTextStyles.caption),
//               ],
//             ),
//           ),
//           const Icon(Icons.more_vert_rounded, color: AppColors.textHint, size: 20),
//         ],
//       ),
//     );
//   }
// }



import 'package:e_learning/core/constants/app_constants.dart';
import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/features/courses/data/model/courses.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VideoPlayerScreen extends StatefulWidget {
  final VideoModel video;
  final VoidCallback? onWatched; // ✅ callback لما الفيديو يخلص

  const VideoPlayerScreen({
    super.key,
    required this.video,
    this.onWatched,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  bool _isPlaying = false;
  bool _showControls = true;
  double _progress = 0.0;
  bool _markedAsWatched = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  String _formatTime(double seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds.toInt() % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  void _onProgressChanged(double v) {
    setState(() => _progress = v);
    // ✅ لو وصل 90% اعتبره اتشاف
    if (v >= 0.9 && !_markedAsWatched) {
      _markedAsWatched = true;
      widget.onWatched?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // ── Video Player ──────────────────────────────────────────────
            GestureDetector(
              onTap: () => setState(() => _showControls = !_showControls),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  color: Colors.black,
                  child: Stack(
                    children: [
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.play_circle_fill_rounded,
                                color: Colors.white.withOpacity(0.12),
                                size: 80),
                            const SizedBox(height: 8),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                widget.video.title,
                                style: const TextStyle(
                                    color: Colors.white24,
                                    fontFamily: 'Poppins',
                                    fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_showControls) ...[
                        // Top Bar
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.7),
                                  Colors.transparent
                                ],
                              ),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      color: Colors.white,
                                      size: 18),
                                  onPressed: () => Navigator.pop(context),
                                ),
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
                                IconButton(
                                  icon: const Icon(Icons.settings_outlined,
                                      color: Colors.white, size: 20),
                                  onPressed: () {},
                                ),
                                IconButton(
                                  icon: const Icon(Icons.fullscreen_rounded,
                                      color: Colors.white, size: 22),
                                  onPressed: () {},
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Play Controls
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () => _onProgressChanged(
                                    (_progress - 0.05).clamp(0.0, 1.0)),
                                child: const Icon(Icons.replay_10_rounded,
                                    color: Colors.white, size: 34),
                              ),
                              const SizedBox(width: 24),
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _isPlaying = !_isPlaying),
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle),
                                  child: Icon(
                                    _isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    color: AppColors.primary,
                                    size: 34,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 24),
                              GestureDetector(
                                onTap: () => _onProgressChanged(
                                    (_progress + 0.05).clamp(0.0, 1.0)),
                                child: const Icon(Icons.forward_10_rounded,
                                    color: Colors.white, size: 34),
                              ),
                            ],
                          ),
                        ),
                        // Bottom Bar
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(0.7),
                                  Colors.transparent
                                ],
                              ),
                            ),
                            child: Column(
                              children: [
                                Slider(
                                  value: _progress,
                                  onChanged: _onProgressChanged,
                                  activeColor: AppColors.accent,
                                  inactiveColor: Colors.white24,
                                  thumbColor: Colors.white,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatTime(_progress * 330),
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 11,
                                            fontFamily: 'Poppins'),
                                      ),
                                      // ✅ Watched indicator
                                      if (_markedAsWatched)
                                        Row(
                                          children: const [
                                            Icon(Icons.check_circle_rounded,
                                                color: AppColors.success,
                                                size: 14),
                                            SizedBox(width: 4),
                                            Text('Watched',
                                                style: TextStyle(
                                                    color: AppColors.success,
                                                    fontSize: 11,
                                                    fontFamily: 'Poppins')),
                                          ],
                                        ),
                                      Text(
                                        widget.video.duration,
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 11,
                                            fontFamily: 'Poppins'),
                                      ),
                                    ],
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
            ),

            // ── Video Info ────────────────────────────────────────────────
            Expanded(
              child: Container(
                color: AppColors.background,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(
                            AppConstants.horizontalPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.video.title,
                                style: AppTextStyles.h2),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.schedule_outlined,
                                    size: 14, color: AppColors.textHint),
                                const SizedBox(width: 4),
                                Text(widget.video.duration,
                                    style: AppTextStyles.bodySmall),
                                const SizedBox(width: 16),
                                const Icon(Icons.visibility_outlined,
                                    size: 14, color: AppColors.textHint),
                                const SizedBox(width: 4),
                                Text('1.2k views',
                                    style: AppTextStyles.bodySmall),
                                if (_markedAsWatched) ...[
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color:
                                          AppColors.success.withOpacity(0.1),
                                      borderRadius:
                                          BorderRadius.circular(100),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                            Icons.check_circle_rounded,
                                            color: AppColors.success,
                                            size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Watched',
                                          style:
                                              AppTextStyles.caption.copyWith(
                                            color: AppColors.success,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: AppColors.divider, height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.horizontalPadding,
                            vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: const [
                            _ActionButton(
                                icon: Icons.thumb_up_alt_outlined,
                                label: 'Like'),
                            _ActionButton(
                                icon: Icons.share_outlined, label: 'Share'),
                            _ActionButton(
                                icon: Icons.download_outlined,
                                label: 'Download'),
                            _ActionButton(
                                icon: Icons.bookmark_border_rounded,
                                label: 'Save'),
                          ],
                        ),
                      ),
                      const Divider(color: AppColors.divider, height: 1),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            AppConstants.horizontalPadding,
                            20,
                            AppConstants.horizontalPadding,
                            12),
                        child: Text('Up Next', style: AppTextStyles.h2),
                      ),
                      ...List.generate(
                          3,
                          (i) => _RelatedVideoItem(
                              index: i + 1, title: widget.video.title)),
                      const SizedBox(height: 20),
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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ActionButton({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 24),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}

class _RelatedVideoItem extends StatelessWidget {
  final int index;
  final String title;
  const _RelatedVideoItem({required this.index, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppConstants.horizontalPadding, 0,
          AppConstants.horizontalPadding, 14),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
            child: Container(
              width: 100,
              height: 64,
              color: AppColors.primary.withOpacity(0.08),
              child: const Center(
                child: Icon(Icons.play_circle_outline_rounded,
                    color: AppColors.primary, size: 28),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lesson ${index + 2}: $title',
                    style: AppTextStyles.h3,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('8:45', style: AppTextStyles.caption),
              ],
            ),
          ),
          const Icon(Icons.more_vert_rounded,
              color: AppColors.textHint, size: 20),
        ],
      ),
    );
  }
}