// ─────────────────────────────────────────────
// create_quiz_screen.dart
// ─────────────────────────────────────────────

import 'package:e_learning/core/erros/app_error_widget.dart';
import 'package:e_learning/core/erros/app_exceptions.dart';
import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/features/admin_panel/create_quiz/presentation/logic/admin_quiz_cubit.dart';
import 'package:e_learning/features/admin_panel/create_quiz/presentation/logic/admin_quiz_states.dart';
import 'package:e_learning/features/admin_panel/create_quiz/presentation/view/add_questions_screen.dart';
import 'package:e_learning/features/admin_panel/create_quiz/presentation/view/widgets/quiz_form_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CreateQuizScreen extends StatefulWidget {
  const CreateQuizScreen({super.key});

  @override
  State<CreateQuizScreen> createState() => _CreateQuizScreenState();
}

class _CreateQuizScreenState extends State<CreateQuizScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _passCtrl = TextEditingController(text: '70');

  List<Map<String, dynamic>> _courses = [];
  String? _selectedCourseId;
  String? _selectedVideoId;
  List<Map<String, dynamic>> _videos = [];

  bool _loadingCourses = true;
  bool _loadingVideos = false;
  bool _saving = false;
  String? _loadCoursesError;

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // ── Fetch courses via cubit ───────────────────────────────────────────────
  Future<void> _fetchCourses() async {
    setState(() {
      _loadingCourses = true;
      _loadCoursesError = null;
    });
    try {
      final courses = await context.read<AdminQuizCubit>().fetchCourses();
      if (mounted) {
        setState(() {
          _courses = courses;
          _loadingCourses = false;
        });
      }
    } on AppException catch (e) {
      if (mounted) setState(() { _loadingCourses = false; _loadCoursesError = e.message; });
    } catch (e) {
      if (mounted) setState(() { _loadingCourses = false; _loadCoursesError = e.toString(); });
    }
  }

  // ── Course selected → load videos via cubit ───────────────────────────────
  void _onCourseSelected(String courseId) {
    setState(() {
      _selectedCourseId = courseId;
      _selectedVideoId = null;
      _videos = [];
    });
    context.read<AdminQuizCubit>().loadVideosForCourse(courseId);
  }

  // ── Save quiz via cubit ───────────────────────────────────────────────────
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCourseId == null || _selectedVideoId == null) {
      _showSnack('Please select a course and a video', isError: true);
      return;
    }

    setState(() => _saving = true);
    try {
      final quiz = await context.read<AdminQuizCubit>().createQuiz(
            videoId: _selectedVideoId!,
            courseId: _selectedCourseId!,
            title: _titleCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            passScore: int.tryParse(_passCtrl.text) ?? 70,
          );

      if (quiz != null && mounted) {
        _showSnack('Quiz created successfully!');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<AdminQuizCubit>(),
              child: AddQuestionsScreen(quiz: quiz),
            ),
          ),
        );
      } else {
        _showSnack('Failed to create quiz', isError: true);
      }
    } on AppException catch (e) {
      _showSnack(e.message, isError: true);
    } catch (e) {
      _showSnack(e.toString(), isError: true);
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

  @override
  Widget build(BuildContext context) {
    if (_loadCoursesError != null && !_loadingCourses) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.background, elevation: 0,
            title: Text('Create Quiz', style: AppTextStyles.h2)),
        body: AppErrorWidget(
          exception: UnknownException(_loadCoursesError!),
          onRetry: _fetchCourses,
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _loadingCourses
          ? const Center(child: CircularProgressIndicator())
          : BlocListener<AdminQuizCubit, AdminQuizState>(
              listenWhen: (_, s) => s is AdminVideosLoading || s is AdminVideosLoaded,
              listener: (_, state) {
                if (state is AdminVideosLoading) {
                  setState(() { _loadingVideos = true; _videos = []; });
                } else if (state is AdminVideosLoaded) {
                  setState(() { _loadingVideos = false; _videos = state.videos; });
                }
              },
              child: _buildForm(),
            ),
    );
  }

  AppBar _buildAppBar() => AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface, shape: BoxShape.circle,
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 16, color: AppColors.textPrimary),
          ),
        ),
        title: Text('Create Quiz', style: AppTextStyles.h2),
      );

  Widget _buildForm() => Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildQuizInfoSection(),
            const SizedBox(height: 16),
            _buildAssignVideoSection(),
            const SizedBox(height: 28),
            _buildSubmitButton(),
          ],
        ),
      );

  Widget _buildQuizInfoSection() => SectionCard(
        title: 'Quiz Info',
        icon: Icons.info_outline_rounded,
        children: [
          QuizFormField(controller: _titleCtrl, label: 'Quiz Title',
              hint: 'e.g. Lesson 1 Quiz', icon: Icons.title_rounded,
              validator: (v) => v!.isEmpty ? 'Required' : null),
          const SizedBox(height: 14),
          QuizFormField(controller: _descCtrl, label: 'Description (optional)',
              hint: 'Short description...', icon: Icons.description_outlined, maxLines: 2),
          const SizedBox(height: 14),
          QuizFormField(controller: _passCtrl, label: 'Pass Score %', hint: '70',
              icon: Icons.percent_rounded, keyboardType: TextInputType.number,
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n < 1 || n > 100) return 'Enter 1-100';
                return null;
              }),
        ],
      );

  Widget _buildAssignVideoSection() => SectionCard(
        title: 'Assign to Video',
        icon: Icons.video_library_outlined,
        children: [
          QuizDropdownField(
            label: 'Select Course', icon: Icons.school_outlined,
            value: _selectedCourseId, hint: 'Select a course',
            items: _courses.map((c) => DropdownMenuItem(
              value: c['id'] as String,
              child: Text(c['title'] as String, overflow: TextOverflow.ellipsis),
            )).toList(),
            onChanged: (v) { if (v != null) _onCourseSelected(v); },
          ),
          const SizedBox(height: 14),
          _buildVideoDropdown(),
        ],
      );

  Widget _buildVideoDropdown() {
    if (_loadingVideos) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        const Icon(Icons.play_circle_outline_rounded, color: AppColors.textHint, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedVideoId,
              isExpanded: true,
              hint: Text(
                _selectedCourseId == null ? 'Select a course first'
                    : _videos.isEmpty ? 'No videos in this course' : 'Select a video',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
              ),
              items: _videos.map((v) => DropdownMenuItem<String>(
                value: v['id'] as String,
                child: Text(v['title'] as String, overflow: TextOverflow.ellipsis),
              )).toList(),
              onChanged: _videos.isEmpty ? null : (val) => setState(() => _selectedVideoId = val),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildSubmitButton() => SizedBox(
        height: 54,
        child: ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: _saving
              ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('Next: Add Questions', style: AppTextStyles.labelLarge),
                ]),
        ),
      );
}
