// screens/create_edit_course_screen.dart

import 'package:e_learning/core/erros/app_exceptions.dart';
import 'package:e_learning/core/erros/network_exception_handler.dart';
import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/features/admin_panel/add_courses/data/repo/admin_courses_repo.dart';
import 'package:e_learning/features/admin_panel/add_courses/presentation/view/widgets/admin_back_button.dart';
import 'package:e_learning/features/admin_panel/add_courses/presentation/view/widgets/form_widgets.dart';
import 'package:e_learning/features/admin_panel/add_courses/presentation/view/widgets/thumbnail_picker.dart';
import 'package:e_learning/features/courses/data/model/courses.dart';
import 'package:flutter/material.dart';

class CreateEditCourseScreen extends StatefulWidget {
  final AdminCoursesRepo repo;
  final CourseModel? course;

  const CreateEditCourseScreen({
    super.key,
    required this.repo,
    this.course,
  });

  @override
  State<CreateEditCourseScreen> createState() =>
      _CreateEditCourseScreenState();
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

  static const _levels = ['Beginner', 'Intermediate', 'Advanced'];
  static const _categories = [
    'Programming', 'Design', 'Business', 'Marketing',
    'Data Science', 'Mobile', 'DevOps', 'Other',
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.course;
    _titleCtrl      = TextEditingController(text: c?.title ?? '');
    _categoryCtrl   = TextEditingController(text: c?.category ?? '');
    _instructorCtrl = TextEditingController(text: c?.instructor ?? '');
    _descCtrl       = TextEditingController(text: c?.description ?? '');
    _thumbnailCtrl  = TextEditingController(text: c?.thumbnailUrl ?? '');
    _durationCtrl   = TextEditingController(text: c?.duration ?? '');
    _ratingCtrl     = TextEditingController(
        text: c?.rating.toStringAsFixed(1) ?? '4.5');
    _level      = c?.level ?? 'Beginner';
    _isFeatured = c?.isFeatured ?? false;
  }

  @override
  void dispose() {
    for (final ctrl in [
      _titleCtrl, _categoryCtrl, _instructorCtrl, _descCtrl,
      _thumbnailCtrl, _durationCtrl, _ratingCtrl,
    ]) {
      ctrl.dispose();
    }
    super.dispose();
  }

  // ── Save ─────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryCtrl.text.isEmpty) {
      _showSnack('Please select a category', isError: true);
      return;
    }
    setState(() => _saving = true);

    try {
      final bool ok;
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        title: Text(_isEdit ? 'Edit Course' : 'New Course',
            style: AppTextStyles.h2),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FormSectionCard(
              title: 'Basic Info',
              icon: Icons.info_outline_rounded,
              children: [
                FormTextField(
                  ctrl: _titleCtrl,
                  label: 'Course Title',
                  hint: 'e.g. Flutter for Beginners',
                  icon: Icons.title_rounded,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                FormTextField(
                  ctrl: _instructorCtrl,
                  label: 'Instructor',
                  hint: 'e.g. Ahmed Mohamed',
                  icon: Icons.person_outline_rounded,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                FormTextField(
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
            FormSectionCard(
              title: 'Category & Level',
              icon: Icons.category_outlined,
              children: [
                FormDropdownField(
                  label: 'Category',
                  icon: Icons.category_outlined,
                  value: _categories.contains(_categoryCtrl.text)
                      ? _categoryCtrl.text
                      : null,
                  hint: 'Select category',
                  items: _categories
                      .map((c) =>
                          DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _categoryCtrl.text = v);
                  },
                ),
                const SizedBox(height: 16),
                LevelSelector(
                  levels: _levels,
                  selected: _level,
                  onChanged: (l) => setState(() => _level = l),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FormSectionCard(
              title: 'Media & Details',
              icon: Icons.image_outlined,
              children: [
                ThumbnailPicker(ctrl: _thumbnailCtrl),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FormTextField(
                        ctrl: _durationCtrl,
                        label: 'Duration',
                        hint: 'e.g. 12h 30m',
                        icon: Icons.schedule_outlined,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FormTextField(
                        ctrl: _ratingCtrl,
                        label: 'Rating',
                        hint: '4.5',
                        icon: Icons.star_outline_rounded,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: (v) {
                          final n = double.tryParse(v ?? '');
                          if (n == null || n < 0 || n > 5) return '0–5';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                FeaturedToggle(
                  value: _isFeatured,
                  onChanged: (v) => setState(() => _isFeatured = v),
                ),
              ],
            ),
            const SizedBox(height: 28),
            _SaveButton(isEdit: _isEdit, saving: _saving, onSave: _save),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Save Button
// ─────────────────────────────────────────────
class _SaveButton extends StatelessWidget {
  final bool isEdit;
  final bool saving;
  final VoidCallback onSave;

  const _SaveButton({
    required this.isEdit,
    required this.saving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: saving ? null : onSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        child: saving
            ? const CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2.5)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isEdit ? Icons.save_rounded : Icons.check_rounded,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isEdit ? 'Save Changes' : 'Create Course',
                    style: AppTextStyles.labelLarge,
                  ),
                ],
              ),
      ),
    );
  }
}