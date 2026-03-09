// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// instructor_dashboard.dart
// ✅ الشاشة الرئيسية للمعلم — 4 sections:
//   1. Stats Overview (إجمالي الكورسات / الطلاب / الكويزات)
//   2. Course Manager  → AdminCoursesScreen
//   3. Quiz Manager    → AdminQuizScreen
//   4. Students Overview (عدد الطلاب في كل كورس)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/features/admin_panel/add_courses/presentation/view/admin_courses_screen.dart';
import 'package:e_learning/features/admin_panel/create_quiz/presentation/view/admin_quiz_screen.dart';
import 'package:e_learning/features/auth/presentaion/view/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Instructor Dashboard
// ─────────────────────────────────────────────────────────────────────────────
class InstructorDashboard extends StatefulWidget {
  final String userId;
  const InstructorDashboard({super.key, required this.userId});

  @override
  State<InstructorDashboard> createState() => _InstructorDashboardState();
}

class _InstructorDashboardState extends State<InstructorDashboard> {
  final _db = Supabase.instance.client;

  // ── Stats ──────────────────────────────────────────────────────────────────
  int _totalCourses = 0;
  int _totalStudents = 0;
  int _totalQuizzes = 0;
  int _totalVideos = 0;

  // ── Courses + Students ─────────────────────────────────────────────────────
  List<_CourseStats> _courseStats = [];
  bool _loading = true;

  // ── Instructor name ────────────────────────────────────────────────────────
  String _instructorName = 'Instructor';
  String _avatarUrl = '';

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _loading = true);
    try {
      // ── Profile ──────────────────────────────────────────────────────────
      final profile = await _db
          .from('profiles')
          .select('name, avatar_url')
          .eq('user_id', widget.userId)
          .maybeSingle();

      if (profile != null) {
        _instructorName =
            (profile as Map<String, dynamic>)['name'] ?? 'Instructor';
        _avatarUrl = profile['avatar_url'] ?? '';
      }

      // ── All courses ───────────────────────────────────────────────────────
      final coursesRaw = await _db
          .from('courses')
          .select('id, title, thumbnail_url, students_count, lessons_count')
          .order('title') as List;

      final courses = coursesRaw.cast<Map<String, dynamic>>();
      _totalCourses = courses.length;

      if (courses.isEmpty) {
        setState(() {
          _courseStats = [];
          _loading = false;
        });
        return;
      }

      final courseIds = courses.map((c) => c['id'] as String).toList();

      // ── Enrollments per course ────────────────────────────────────────────
      final enrollmentsRaw = await _db
          .from('enrollments')
          .select('course_id')
          .inFilter('course_id', courseIds) as List;

      final Map<String, int> enrollMap = {};
      for (final e in enrollmentsRaw.cast<Map<String, dynamic>>()) {
        final id = e['course_id'] as String;
        enrollMap[id] = (enrollMap[id] ?? 0) + 1;
      }

      // ── Completed enrollments per course ──────────────────────────────────
      final completedRaw = await _db
          .from('enrollments')
          .select('course_id')
          .inFilter('course_id', courseIds)
          .not('completed_at', 'is', null) as List;

      final Map<String, int> completedMap = {};
      for (final e in completedRaw.cast<Map<String, dynamic>>()) {
        final id = e['course_id'] as String;
        completedMap[id] = (completedMap[id] ?? 0) + 1;
      }

      // ── Quizzes per course ────────────────────────────────────────────────
      final quizzesRaw = await _db
          .from('quizzes')
          .select('id, course_id')
          .inFilter('course_id', courseIds) as List;

      final Map<String, int> quizMap = {};
      for (final q in quizzesRaw.cast<Map<String, dynamic>>()) {
        final id = q['course_id'] as String;
        quizMap[id] = (quizMap[id] ?? 0) + 1;
      }

      // ── Videos per course ─────────────────────────────────────────────────
      final videosRaw = await _db
          .from('videos')
          .select('id, course_id')
          .inFilter('course_id', courseIds) as List;

      final Map<String, int> videoMap = {};
      for (final v in videosRaw.cast<Map<String, dynamic>>()) {
        final id = v['course_id'] as String;
        videoMap[id] = (videoMap[id] ?? 0) + 1;
      }

      // ── Build stats list ──────────────────────────────────────────────────
      final stats = courses.map((c) {
        final id = c['id'] as String;
        return _CourseStats(
          courseId: id,
          title: c['title'] ?? '',
          thumbnail: c['thumbnail_url'] ?? '',
          students: enrollMap[id] ?? 0,
          completed: completedMap[id] ?? 0,
          quizzes: quizMap[id] ?? 0,
          videos: videoMap[id] ?? 0,
        );
      }).toList();

      // Sort by students descending
      stats.sort((a, b) => b.students.compareTo(a.students));

      _totalStudents =
          enrollMap.values.fold(0, (sum, v) => sum + v);
      _totalQuizzes = quizMap.values.fold(0, (sum, v) => sum + v);
      _totalVideos = videoMap.values.fold(0, (sum, v) => sum + v);

      setState(() {
        _courseStats = stats;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Dashboard error: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────────────────────────
            SliverToBoxAdapter(child: _DashboardHeader(
              name: _instructorName,
              avatarUrl: _avatarUrl,
              onLogout: _logout,
            )),

            if (_loading)
              const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()))
            else ...[
              // ── Stats Cards ────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: Column(
                    children: [
                      Row(children: [
                        Expanded(
                          child: _BigStatCard(
                            value: '$_totalStudents',
                            label: 'Total Students',
                            icon: Icons.people_alt_rounded,
                            color: AppColors.primary,
                            gradient: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _BigStatCard(
                            value: '$_totalCourses',
                            label: 'Courses',
                            icon: Icons.school_rounded,
                            color: AppColors.success,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                          child: _BigStatCard(
                            value: '$_totalVideos',
                            label: 'Videos',
                            icon: Icons.play_circle_rounded,
                            color: AppColors.warning,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _BigStatCard(
                            value: '$_totalQuizzes',
                            label: 'Quizzes',
                            icon: Icons.quiz_rounded,
                            color: AppColors.error,
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 28)),

              // ── Quick Actions ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quick Actions', style: AppTextStyles.h2),
                      const SizedBox(height: 14),
                      Row(children: [
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.add_circle_rounded,
                            label: 'New Course',
                            sublabel: 'Add & manage courses',
                            color: AppColors.primary,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const AdminCoursesScreen(),
                                ),
                              );
                              _loadDashboard();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.quiz_rounded,
                            label: 'New Quiz',
                            sublabel: 'Create quiz & questions',
                            color: AppColors.warning,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AdminQuizScreen(),
                                ),
                              );
                              _loadDashboard();
                            },
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 28)),

              // ── Students Overview ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Students per Course', style: AppTextStyles.h2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          '$_totalStudents total',
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 14)),

              if (_courseStats.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.school_outlined,
                              size: 56, color: AppColors.textHint),
                          const SizedBox(height: 12),
                          Text('No courses yet',
                              style: AppTextStyles.h2),
                          const SizedBox(height: 8),
                          Text('Create your first course to see students',
                              style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary),
                              textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _CourseStudentCard(
                        stats: _courseStats[i],
                        rank: i + 1,
                        maxStudents: _courseStats.isEmpty
                            ? 1
                            : _courseStats.first.students,
                      ),
                      childCount: _courseStats.length,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dashboard Header
// ─────────────────────────────────────────────────────────────────────────────
class _DashboardHeader extends StatelessWidget {
  final String name;
  final String avatarUrl;
  final VoidCallback onLogout;

  const _DashboardHeader({
    required this.name,
    required this.avatarUrl,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(children: [
                      const Icon(Icons.verified_rounded,
                          color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Text('Instructor Panel',
                          style: AppTextStyles.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                    ]),
                  ),
                  // Logout
                  GestureDetector(
                    onTap: onLogout,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.logout_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Avatar + name
              Row(children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withOpacity(0.25),
                  backgroundImage: avatarUrl.isNotEmpty
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: avatarUrl.isEmpty
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'I',
                          style: AppTextStyles.h1
                              .copyWith(color: Colors.white),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$greeting 👋',
                        style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white.withOpacity(0.8)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        name.isNotEmpty ? name : 'Instructor',
                        style: AppTextStyles.h1
                            .copyWith(color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Big Stat Card
// ─────────────────────────────────────────────────────────────────────────────
class _BigStatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final bool gradient;

  const _BigStatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    this.gradient = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: gradient
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withOpacity(0.7)],
              )
            : null,
        color: gradient ? null : color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: gradient
            ? null
            : Border.all(color: color.withOpacity(0.2)),
        boxShadow: gradient
            ? [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                )
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: gradient
                  ? Colors.white.withOpacity(0.2)
                  : color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon,
                color: gradient ? Colors.white : color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTextStyles.displayMedium.copyWith(
              color: gradient ? Colors.white : color,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: gradient
                  ? Colors.white.withOpacity(0.85)
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action Card
// ─────────────────────────────────────────────────────────────────────────────
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(label,
                style:
                    AppTextStyles.h3.copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: 3),
            Text(sublabel,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('Open',
                    style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700)),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_rounded,
                    color: Colors.white, size: 13),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Course Student Card
// ─────────────────────────────────────────────────────────────────────────────
class _CourseStudentCard extends StatelessWidget {
  final _CourseStats stats;
  final int rank;
  final int maxStudents;

  const _CourseStudentCard({
    required this.stats,
    required this.rank,
    required this.maxStudents,
  });

  @override
  Widget build(BuildContext context) {
    final progress =
        maxStudents == 0 ? 0.0 : stats.students / maxStudents;
    final completionRate = stats.students == 0
        ? 0.0
        : stats.completed / stats.students;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Rank badge
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: rank == 1
                        ? AppColors.warning.withOpacity(0.15)
                        : rank == 2
                            ? AppColors.textSecondary.withOpacity(0.1)
                            : rank == 3
                                ? const Color(0xFFCD7F32).withOpacity(0.1)
                                : AppColors.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: rank <= 3
                        ? Icon(
                            Icons.emoji_events_rounded,
                            size: 18,
                            color: rank == 1
                                ? AppColors.warning
                                : rank == 2
                                    ? AppColors.textSecondary
                                    : const Color(0xFFCD7F32),
                          )
                        : Text(
                            '#$rank',
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
                const SizedBox(width: 12),

                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: stats.thumbnail.isNotEmpty
                      ? Image.network(stats.thumbnail,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _CoursePlaceholder())
                      : _CoursePlaceholder(),
                ),
                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(stats.title,
                          style: AppTextStyles.h3,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Row(children: [
                        _MiniChip(
                          icon: Icons.people_alt_rounded,
                          label: '${stats.students}',
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        _MiniChip(
                          icon: Icons.play_circle_outline_rounded,
                          label: '${stats.videos}',
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 8),
                        _MiniChip(
                          icon: Icons.quiz_outlined,
                          label: '${stats.quizzes}',
                          color: AppColors.warning,
                        ),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Progress bars
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                // Enrollment bar
                _ProgressRow(
                  label: 'Enrolled',
                  value: stats.students,
                  maxValue: maxStudents,
                  progress: progress,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 8),
                // Completion bar
                _ProgressRow(
                  label: 'Completed',
                  value: stats.completed,
                  maxValue: stats.students,
                  progress: completionRate,
                  color: AppColors.success,
                  suffix: stats.students > 0
                      ? '${(completionRate * 100).round()}%'
                      : '0%',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CoursePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient),
        child: const Icon(Icons.school_outlined,
            color: Colors.white, size: 22),
      );
}

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _MiniChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 3),
          Text(label,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary)),
        ],
      );
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final int value;
  final int maxValue;
  final double progress;
  final Color color;
  final String? suffix;

  const _ProgressRow({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.progress,
    required this.color,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 68,
          child: Text(label,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 36,
          child: Text(
            suffix ?? '$value',
            style: AppTextStyles.caption.copyWith(
                color: color, fontWeight: FontWeight.w700),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data Model
// ─────────────────────────────────────────────────────────────────────────────
class _CourseStats {
  final String courseId;
  final String title;
  final String thumbnail;
  final int students;
  final int completed;
  final int quizzes;
  final int videos;

  const _CourseStats({
    required this.courseId,
    required this.title,
    required this.thumbnail,
    required this.students,
    required this.completed,
    required this.quizzes,
    required this.videos,
  });
}