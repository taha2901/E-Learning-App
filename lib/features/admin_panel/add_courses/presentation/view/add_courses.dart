import 'package:e_learning/core/erros/app_error_widget.dart';
import 'package:e_learning/core/erros/app_exceptions.dart';
import 'package:e_learning/core/erros/network_exception_handler.dart';
import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/features/courses/data/model/courses.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Repo
// ─────────────────────────────────────────────────────────────────────────────
class AdminCoursesRepo {
  final _db = Supabase.instance.client;

  Future<List<CourseModel>> fetchAllCourses() async {
    try {
      final list = await _db.from('courses').select().order('title') as List;
      final courses = list
          .map((e) => CourseModel.fromJson(e as Map<String, dynamic>))
          .toList();

      if (courses.isEmpty) return [];
      final ids = courses.map((c) => c.id).toList();
      final videos =
          await _db.from('videos').select().inFilter('course_id', ids) as List;

      final Map<String, List<VideoModel>> map = {};
      for (final v in videos) {
        final video = VideoModel.fromJson(v as Map<String, dynamic>);
        map.putIfAbsent(video.courseId, () => []).add(video);
      }

      return courses.map((c) => c.copyWith(videos: map[c.id] ?? [])).toList();
    } catch (e) {
      throw NetworkExceptionHandler.handle(e);
    }
  }

  Future<String?> createCourse({
    required String title,
    required String category,
    required String instructor,
    required String description,
    required String thumbnailUrl,
    required String duration,
    required String level,
    required double rating,
    required bool isFeatured,
  }) async {
    try {
      final res = await _db
          .from('courses')
          .insert({
            'title': title,
            'category': category,
            'instructor': instructor,
            'description': description,
            'thumbnail_url': thumbnailUrl,
            'duration': duration,
            'level': level,
            'rating': rating,
            'is_featured': isFeatured,
            'students_count': 0,
            'lessons_count': 0,
          })
          .select('id')
          .single();
      return (res as Map<String, dynamic>)['id'] as String;
    } catch (e) {
      throw NetworkExceptionHandler.handle(e);
    }
  }

  Future<bool> updateCourse({
    required String courseId,
    required String title,
    required String category,
    required String instructor,
    required String description,
    required String thumbnailUrl,
    required String duration,
    required String level,
    required double rating,
    required bool isFeatured,
  }) async {
    try {
      await _db
          .from('courses')
          .update({
            'title': title,
            'category': category,
            'instructor': instructor,
            'description': description,
            'thumbnail_url': thumbnailUrl,
            'duration': duration,
            'level': level,
            'rating': rating,
            'is_featured': isFeatured,
          })
          .eq('id', courseId);
      return true;
    } catch (e) {
      throw NetworkExceptionHandler.handle(e);
    }
  }

  Future<bool> deleteCourse(String courseId) async {
    try {
      await _db.from('courses').delete().eq('id', courseId);
      return true;
    } catch (e) {
      throw NetworkExceptionHandler.handle(e);
    }
  }

  Future<String?> addVideo({
    required String courseId,
    required String title,
    required String duration,
    required String videoUrl,
    required bool isLocked,
  }) async {
    try {
      final res = await _db
          .from('videos')
          .insert({
            'course_id': courseId,
            'title': title,
            'duration': duration,
            'video_url': videoUrl,
            'is_locked': isLocked,
            'is_watched': false,
          })
          .select('id')
          .single();

      final countRes = await _db
          .from('videos')
          .select('id')
          .eq('course_id', courseId);
      await _db
          .from('courses')
          .update({'lessons_count': (countRes as List).length})
          .eq('id', courseId);

      return (res as Map<String, dynamic>)['id'] as String;
    } catch (e) {
      throw NetworkExceptionHandler.handle(e);
    }
  }

  Future<bool> deleteVideo(String videoId, String courseId) async {
    try {
      await _db.from('videos').delete().eq('id', videoId);
      final countRes = await _db
          .from('videos')
          .select('id')
          .eq('course_id', courseId);
      await _db
          .from('courses')
          .update({'lessons_count': (countRes as List).length})
          .eq('id', courseId);
      return true;
    } catch (e) {
      throw NetworkExceptionHandler.handle(e);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main Screen
// ─────────────────────────────────────────────────────────────────────────────
class AdminCoursesScreen extends StatefulWidget {
  const AdminCoursesScreen({super.key});

  @override
  State<AdminCoursesScreen> createState() => _AdminCoursesScreenState();
}

class _AdminCoursesScreenState extends State<AdminCoursesScreen> {
  final _repo = AdminCoursesRepo();
  List<CourseModel> _courses = [];
  bool _loading = true;
  AppException? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final courses = await _repo.fetchAllCourses();
      if (mounted) {
        setState(() {
          _courses = courses;
          _loading = false;
        });
      }
    } on AppException catch (e) {
      if (mounted)
        setState(() {
          _loading = false;
          _loadError = e;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _loading = false;
          _loadError = NetworkExceptionHandler.handle(e);
        });
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Course Manager', style: AppTextStyles.h2),
                Text(
                  '${_courses.length} courses',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateEditCourseScreen(repo: _repo),
                      ),
                    );
                    _load();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'New Course',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ✅ Error State
          if (_loadError != null && !_loading)
            SliverFillRemaining(
              child: AppErrorWidget(exception: _loadError!, onRetry: _load),
            )
          else if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_courses.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.06),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.school_outlined,
                        size: 48,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('No courses yet', style: AppTextStyles.h2),
                    const SizedBox(height: 8),
                    Text(
                      'Tap "New Course" to get started',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _CourseAdminCard(
                    course: _courses[i],
                    onEdit: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreateEditCourseScreen(
                            repo: _repo,
                            course: _courses[i],
                          ),
                        ),
                      );
                      _load();
                    },
                    onManageVideos: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ManageVideosScreen(
                            course: _courses[i],
                            repo: _repo,
                          ),
                        ),
                      );
                      _load();
                    },
                    onDelete: () async {
                      try {
                        await _repo.deleteCourse(_courses[i].id);
                        _load();
                      } on AppException catch (e) {
                        _showSnack(e.message, isError: true);
                      }
                    },
                  ),
                  childCount: _courses.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Course Admin Card
// ─────────────────────────────────────────────────────────────────────────────
class _CourseAdminCard extends StatelessWidget {
  final CourseModel course;
  final VoidCallback onEdit;
  final VoidCallback onManageVideos;
  final VoidCallback onDelete;

  const _CourseAdminCard({
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
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: Stack(
              children: [
                course.thumbnailUrl.isNotEmpty
                    ? Image.network(
                        course.thumbnailUrl,
                        height: 130,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _PlaceholderThumb(),
                      )
                    : _PlaceholderThumb(),
                if (course.isFeatured)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Featured',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _Pill(
                      label: course.category,
                      color: AppColors.primary.withOpacity(0.1),
                      textColor: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    _Pill(
                      label: course.level,
                      color: AppColors.surfaceVariant,
                      textColor: AppColors.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(course.title, style: AppTextStyles.h3),
                const SizedBox(height: 2),
                Text(
                  course.instructor,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    _StatChip(
                      icon: Icons.play_circle_outline_rounded,
                      label: '${course.videos.length} videos',
                    ),
                    const SizedBox(width: 12),
                    _StatChip(
                      icon: Icons.schedule_outlined,
                      label: course.duration,
                    ),
                    const SizedBox(width: 12),
                    _StatChip(
                      icon: Icons.star_rounded,
                      label: course.rating.toStringAsFixed(1),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _CardBtn(
                        icon: Icons.edit_rounded,
                        label: 'Edit',
                        color: AppColors.primary,
                        onTap: onEdit,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _CardBtn(
                        icon: Icons.video_library_rounded,
                        label: 'Videos (${course.videos.length})',
                        color: AppColors.success,
                        onTap: onManageVideos,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _confirmDelete(context),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: AppColors.error,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
            onPressed: () {
              Navigator.pop(ctx);
              onDelete();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderThumb extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    height: 130,
    width: double.infinity,
    decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
    child: const Center(
      child: Icon(Icons.school_outlined, color: Colors.white, size: 48),
    ),
  );
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  const _Pill({
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) => Container(
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

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: AppColors.textHint),
      const SizedBox(width: 4),
      Text(
        label,
        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
      ),
    ],
  );
}

class _CardBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _CardBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
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

// ─────────────────────────────────────────────────────────────────────────────
// Create / Edit Course Screen — with error handling
// ─────────────────────────────────────────────────────────────────────────────
class CreateEditCourseScreen extends StatefulWidget {
  final AdminCoursesRepo repo;
  final CourseModel? course;

  const CreateEditCourseScreen({super.key, required this.repo, this.course});

  @override
  State<CreateEditCourseScreen> createState() => _CreateEditCourseScreenState();
}

class _CreateEditCourseScreenState extends State<CreateEditCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _instructorCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _thumbnailCtrl;
  late final TextEditingController _durationCtrl;
  late final TextEditingController _ratingCtrl;
  String _level = 'Beginner';
  bool _isFeatured = false;
  bool _saving = false;

  bool get _isEdit => widget.course != null;

  final _levels = ['Beginner', 'Intermediate', 'Advanced'];
  final _categories = [
    'Programming',
    'Design',
    'Business',
    'Marketing',
    'Data Science',
    'Mobile',
    'DevOps',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.course;
    _titleCtrl = TextEditingController(text: c?.title ?? '');
    _categoryCtrl = TextEditingController(text: c?.category ?? '');
    _instructorCtrl = TextEditingController(text: c?.instructor ?? '');
    _descCtrl = TextEditingController(text: c?.description ?? '');
    _thumbnailCtrl = TextEditingController(text: c?.thumbnailUrl ?? '');
    _durationCtrl = TextEditingController(text: c?.duration ?? '');
    _ratingCtrl = TextEditingController(
      text: c?.rating.toStringAsFixed(1) ?? '4.5',
    );
    _level = c?.level ?? 'Beginner';
    _isFeatured = c?.isFeatured ?? false;
  }

  @override
  void dispose() {
    for (final ctrl in [
      _titleCtrl,
      _categoryCtrl,
      _instructorCtrl,
      _descCtrl,
      _thumbnailCtrl,
      _durationCtrl,
      _ratingCtrl,
    ]) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryCtrl.text.isEmpty) {
      _showSnack('Please select a category', isError: true);
      return;
    }
    setState(() => _saving = true);

    try {
      bool ok;
      if (_isEdit) {
        ok = await widget.repo.updateCourse(
          courseId: widget.course!.id,
          title: _titleCtrl.text.trim(),
          category: _categoryCtrl.text.trim(),
          instructor: _instructorCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          thumbnailUrl: _thumbnailCtrl.text.trim(),
          duration: _durationCtrl.text.trim(),
          level: _level,
          rating: double.tryParse(_ratingCtrl.text) ?? 4.5,
          isFeatured: _isFeatured,
        );
      } else {
        final id = await widget.repo.createCourse(
          title: _titleCtrl.text.trim(),
          category: _categoryCtrl.text.trim(),
          instructor: _instructorCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          thumbnailUrl: _thumbnailCtrl.text.trim(),
          duration: _durationCtrl.text.trim(),
          level: _level,
          rating: double.tryParse(_ratingCtrl.text) ?? 4.5,
          isFeatured: _isFeatured,
        );
        ok = id != null;
      }

      if (!mounted) return;
      if (ok) {
        _showSnack(_isEdit ? 'Course updated!' : 'Course created!');
        Navigator.pop(context);
      } else {
        _showSnack('Something went wrong. Try again.', isError: true);
      }
    } on AppException catch (e) {
      _showSnack(e.message, isError: true);
    } catch (e) {
      _showSnack(NetworkExceptionHandler.handle(e).message, isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        title: Text(
          _isEdit ? 'Edit Course' : 'New Course',
          style: AppTextStyles.h2,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionCard(
              title: 'Basic Info',
              icon: Icons.info_outline_rounded,
              children: [
                _Field(
                  ctrl: _titleCtrl,
                  label: 'Course Title',
                  hint: 'e.g. Flutter for Beginners',
                  icon: Icons.title_rounded,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                _Field(
                  ctrl: _instructorCtrl,
                  label: 'Instructor',
                  hint: 'e.g. Ahmed Mohamed',
                  icon: Icons.person_outline_rounded,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                _Field(
                  ctrl: _descCtrl,
                  label: 'Description',
                  hint: 'Course description...',
                  icon: Icons.description_outlined,
                  maxLines: 3,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Category & Level',
              icon: Icons.category_outlined,
              children: [
                _DropdownField(
                  label: 'Category',
                  icon: Icons.category_outlined,
                  value: _categories.contains(_categoryCtrl.text)
                      ? _categoryCtrl.text
                      : null,
                  hint: 'Select category',
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _categoryCtrl.text = v);
                  },
                ),
                const SizedBox(height: 16),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.signal_cellular_alt_rounded,
                          color: AppColors.textHint,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text('Level:', style: AppTextStyles.bodySmall),
                      ],
                    ),
                    ..._levels.map(
                      (l) => GestureDetector(
                        onTap: () => setState(() => _level = l),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: _level == l
                                ? AppColors.primary
                                : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            l,
                            style: AppTextStyles.caption.copyWith(
                              color: _level == l
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Media & Details',
              icon: Icons.image_outlined,
              children: [
                _ThumbnailPicker(ctrl: _thumbnailCtrl),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _Field(
                        ctrl: _durationCtrl,
                        label: 'Duration',
                        hint: 'e.g. 12h 30m',
                        icon: Icons.schedule_outlined,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Field(
                        ctrl: _ratingCtrl,
                        label: 'Rating',
                        hint: '4.5',
                        icon: Icons.star_outline_rounded,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (v) {
                          final n = double.tryParse(v ?? '');
                          if (n == null || n < 0 || n > 5) return '0-5';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.cardBorder),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: AppColors.warning,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Featured Course',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),
                      Switch(
                        value: _isFeatured,
                        onChanged: (v) => setState(() => _isFeatured = v),
                        activeColor: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _saving
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isEdit ? Icons.save_rounded : Icons.check_rounded,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isEdit ? 'Save Changes' : 'Create Course',
                            style: AppTextStyles.labelLarge,
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Manage Videos Screen — with error handling
// ─────────────────────────────────────────────────────────────────────────────
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

  Future<void> _addVideo() async {
    if (_isAdding) return;
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _AddVideoSheet(),
    );

    if (result != null && mounted) {
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

      setState(() {
        _videos = [..._videos, tempVideo];
        _isAdding = true;
      });

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
            _videos = _videos
                .map(
                  (v) => v.id == tempId
                      ? VideoModel(
                          id: id,
                          courseId: widget.course.id,
                          title: result['title'],
                          duration: result['duration'],
                          videoUrl: result['video_url'],
                          isLocked: result['is_locked'],
                          isWatched: false,
                        )
                      : v,
                )
                .toList();
          });
          _showSnack('Video added!');
        }
      } on AppException catch (e) {
        // ✅ Rollback
        if (mounted) {
          setState(
            () => _videos = _videos.where((v) => v.id != tempId).toList(),
          );
          _showSnack(e.message, isError: true);
        }
      } catch (e) {
        if (mounted) {
          setState(
            () => _videos = _videos.where((v) => v.id != tempId).toList(),
          );
          _showSnack(NetworkExceptionHandler.handle(e).message, isError: true);
        }
      } finally {
        if (mounted) setState(() => _isAdding = false);
      }
    }
  }

  Future<void> _deleteVideo(VideoModel video) async {
    setState(() => _videos = _videos.where((v) => v.id != video.id).toList());
    try {
      await widget.repo.deleteVideo(video.id, widget.course.id);
    } on AppException catch (e) {
      // ✅ Rollback
      if (mounted) {
        setState(() => _videos = [..._videos, video]);
        _showSnack(e.message, isError: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _videos = [..._videos, video]);
        _showSnack(NetworkExceptionHandler.handle(e).message, isError: true);
      }
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Videos', style: AppTextStyles.h2),
            Text(
              widget.course.title,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
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
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _isAdding
                      ? AppColors.primary.withOpacity(0.5)
                      : AppColors.primary,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: _isAdding
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        children: [
                          const Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Add',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
      body: _videos.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.video_library_outlined,
                    size: 56,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(height: 16),
                  Text('No videos yet', style: AppTextStyles.h2),
                  const SizedBox(height: 8),
                  Text(
                    'Tap "Add" to add lessons',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _videos.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final video = _videos[i];
                final isTemp = video.id.startsWith('temp_');
                return AnimatedOpacity(
                  opacity: isTemp ? 0.6 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isTemp
                            ? AppColors.primary.withOpacity(0.3)
                            : AppColors.cardBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
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
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                )
                              : Icon(
                                  video.isLocked
                                      ? Icons.lock_outline_rounded
                                      : Icons.play_arrow_rounded,
                                  color: video.isLocked
                                      ? AppColors.error
                                      : AppColors.success,
                                  size: 20,
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                video.title,
                                style: AppTextStyles.h3,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.schedule_outlined,
                                    size: 12,
                                    color: AppColors.textHint,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    video.duration,
                                    style: AppTextStyles.caption,
                                  ),
                                  if (video.isLocked) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.error.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(
                                          100,
                                        ),
                                      ),
                                      child: Text(
                                        'Locked',
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.error,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (!isTemp)
                          GestureDetector(
                            onTap: () => _confirmDeleteVideo(context, video),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.delete_outline_rounded,
                                color: AppColors.error,
                                size: 16,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Video?', style: AppTextStyles.h2),
        content: Text(
          'Delete "${video.title}"?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteVideo(video);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add Video Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _AddVideoSheet extends StatefulWidget {
  const _AddVideoSheet();

  @override
  State<_AddVideoSheet> createState() => _AddVideoSheetState();
}

class _AddVideoSheetState extends State<_AddVideoSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  bool _isLocked = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _durationCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text('Add Video', style: AppTextStyles.h2),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SheetField(
                ctrl: _titleCtrl,
                label: 'Video Title',
                icon: Icons.title_rounded,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              _SheetField(
                ctrl: _durationCtrl,
                label: 'Duration (e.g. 10:30)',
                icon: Icons.schedule_outlined,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              _SheetField(
                ctrl: _urlCtrl,
                label: 'Video URL',
                icon: Icons.link_rounded,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.cardBorder),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.textHint,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Locked (Premium)',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                    Switch(
                      value: _isLocked,
                      onChanged: (v) => setState(() => _isLocked = v),
                      activeColor: AppColors.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.pop(context, {
                        'title': _titleCtrl.text.trim(),
                        'duration': _durationCtrl.text.trim(),
                        'video_url': _urlCtrl.text.trim(),
                        'is_locked': _isLocked,
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text('Add Video', style: AppTextStyles.labelLarge),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final String? Function(String?)? validator;
  const _SheetField({
    required this.ctrl,
    required this.label,
    required this.icon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: ctrl,
    validator: validator,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
  );
}

// ─────────────────────────────────────────────
// Shared Widgets
// ─────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(title, style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _Field({
    required this.ctrl,
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: ctrl,
    maxLines: maxLines,
    keyboardType: keyboardType,
    validator: validator,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
  );
}

class _DropdownField extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?>? onChanged;
  final String? hint;

  const _DropdownField({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
    decoration: BoxDecoration(
      border: Border.all(color: AppColors.cardBorder),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(icon, color: AppColors.textHint, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text(
                hint ?? label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textHint,
                ),
              ),
              isExpanded: true,
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    ),
  );
}






class _ThumbnailPicker extends StatefulWidget {
  final TextEditingController ctrl;
  const _ThumbnailPicker({required this.ctrl});

  @override
  State<_ThumbnailPicker> createState() => _ThumbnailPickerState();
}

class _ThumbnailPickerState extends State<_ThumbnailPicker> {
  @override
  Widget build(BuildContext context) {
    final hasUrl = widget.ctrl.text.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Preview لو في صورة
        if (hasUrl)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              widget.ctrl.text,
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 140,
                decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient),
                child: const Center(
                    child: Icon(Icons.broken_image_rounded,
                        color: Colors.white54, size: 40)),
              ),
            ),
          ),
        if (hasUrl) const SizedBox(height: 10),

        // Buttons Row
        Row(
          children: [
            // اختيار من الجاليري
            Expanded(
              child: GestureDetector(
                onTap: _pickFromGallery,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.photo_library_rounded,
                          color: AppColors.primary, size: 18),
                      const SizedBox(width: 6),
                      Text('Gallery',
                          style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // URL يدوي
            Expanded(
              child: GestureDetector(
                onTap: _enterUrl,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.link_rounded,
                          color: AppColors.textSecondary, size: 18),
                      const SizedBox(width: 6),
                      Text('URL',
                          style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        // URL field لو اختار URL
        if (hasUrl) ...[
          const SizedBox(height: 10),
          TextFormField(
            controller: widget.ctrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Thumbnail URL',
              prefixIcon: const Icon(Icons.image_outlined),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear_rounded,
                    color: AppColors.textHint),
                onPressed: () =>
                    setState(() => widget.ctrl.clear()),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;

    // Upload to Supabase Storage
    try {
      final bytes = await file.readAsBytes();
      final ext = file.path.split('.').last;
      final fileName = 'thumbnails/${DateTime.now().millisecondsSinceEpoch}.$ext';

      await Supabase.instance.client.storage
          .from('course-images')
          .uploadBinary(fileName, bytes,
              fileOptions: FileOptions(contentType: 'image/$ext'));

      final url = Supabase.instance.client.storage
          .from('course-images')
          .getPublicUrl(fileName);

      if (mounted) setState(() => widget.ctrl.text = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _enterUrl() {
    // لو مفيش URL — اضهر field فاضي عشان يكتب
    setState(() {
      if (widget.ctrl.text.isEmpty) {
        widget.ctrl.text = 'https://';
      }
    });
  }
}