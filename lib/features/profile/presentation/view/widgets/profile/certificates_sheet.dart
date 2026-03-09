// sheets/certificates_sheet.dart

import 'package:e_learning/core/erros/app_error_widget.dart';
import 'package:e_learning/core/erros/app_exceptions.dart';
import 'package:e_learning/core/erros/network_exception_handler.dart';
import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/features/profile/data/models/certificate_data.dart';
import 'package:e_learning/features/profile/presentation/view/certificate_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CertificatesSheet extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> user;

  const CertificatesSheet({
    super.key,
    required this.userId,
    required this.user,
  });

  @override
  State<CertificatesSheet> createState() => _CertificatesSheetState();
}

class _CertificatesSheetState extends State<CertificatesSheet> {
  List<Map<String, dynamic>> _completedCourses = [];
  bool _loading = true;
  AppException? _error;

  @override
  void initState() {
    super.initState();
    _loadCompletedCourses();
  }

  Future<void> _loadCompletedCourses() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final enrollmentsRaw = await Supabase.instance.client
          .from('enrollments')
          .select('course_id, completed_at')
          .eq('user_id', widget.userId)
          .not('completed_at', 'is', null)
          .order('completed_at', ascending: false);

      final enrollments =
          (enrollmentsRaw as List).cast<Map<String, dynamic>>();

      if (enrollments.isEmpty) {
        setState(() => _loading = false);
        return;
      }

      final courseIds =
          enrollments.map((e) => e['course_id'] as String).toList();

      final coursesRaw = await Supabase.instance.client
          .from('courses')
          .select('id, title, instructor')
          .inFilter('id', courseIds);

      final coursesMap = {
        for (final c in (coursesRaw as List).cast<Map<String, dynamic>>())
          c['id'] as String: c,
      };

      final merged = enrollments.map((e) {
        final courseId = e['course_id'] as String;
        return {
          'course_id': courseId,
          'completed_at': e['completed_at'],
          'courses': coursesMap[courseId] ?? {},
        };
      }).toList();

      setState(() {
        _completedCourses = merged;
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
      initialChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (ctx, scrollCtrl) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: Column(
          children: [
            _SheetHandle(),
            const SizedBox(height: 16),
            _SheetTitleRow(
              title: 'My Certificates',
              onClose: () => Navigator.pop(context),
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildBody(scrollCtrl)),
            const SizedBox(height: 16),
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
      return AppErrorWidget(
        exception: _error!,
        onRetry: _loadCompletedCourses,
      );
    }
    if (_completedCourses.isEmpty) {
      return const _EmptyState(
        icon: Icons.workspace_premium_outlined,
        message: 'Complete a course to earn your first certificate!',
      );
    }
    return ListView.separated(
      controller: scrollCtrl,
      itemCount: _completedCourses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _buildTile(i),
    );
  }

  Widget _buildTile(int i) {
    final enrollment = _completedCourses[i];
    final course     = enrollment['courses'] as Map<String, dynamic>? ?? {};
    final courseTitle   = course['title']?.toString() ?? 'Course #${i + 1}';
    final instructor    = course['instructor']?.toString() ?? 'Instructor';
    final completedAt   = DateTime.tryParse(
          enrollment['completed_at']?.toString() ?? '',
        ) ?? DateTime.now();
    final studentName   = widget.user['name']?.toString() ?? 'Student';
    final certId        =
        'LF-${enrollment['course_id'].toString().substring(0, 8).toUpperCase()}';

    return CertificateListTile(
      index: i + 1,
      courseTitle: courseTitle,
      completedAt: completedAt,
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CertificateScreen(
              data: CertificateData(
                studentName: studentName,
                courseName: courseTitle,
                instructorName: instructor,
                completionDate: completedAt,
                certificateId: certId,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Certificate List Tile
// ─────────────────────────────────────────────
class CertificateListTile extends StatelessWidget {
  final int index;
  final String courseTitle;
  final DateTime completedAt;
  final VoidCallback onTap;

  const CertificateListTile({
    super.key,
    required this.index,
    required this.courseTitle,
    required this.completedAt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${completedAt.day}/${completedAt.month}/${completedAt.year}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.workspace_premium_rounded,
                  color: AppColors.warning, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Certificate of Completion #$index',
                      style: AppTextStyles.h3),
                  const SizedBox(height: 2),
                  Text(
                    courseTitle,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Completed $dateStr',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textHint),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.arrow_forward_ios_rounded,
                  color: AppColors.primary, size: 14),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Shared sheet helpers
// ─────────────────────────────────────────────
class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.cardBorder,
        borderRadius: BorderRadius.circular(100),
      ),
    );
  }
}

class _SheetTitleRow extends StatelessWidget {
  final String title;
  final VoidCallback onClose;

  const _SheetTitleRow({required this.title, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: AppTextStyles.h2),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: onClose,
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: AppColors.textHint),
          const SizedBox(height: 12),
          Text(
            message,
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}