import 'dart:io';
import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/core/widgets/custom_btn.dart';
import 'package:e_learning/core/widgets/custom_text_feild.dart';
import 'package:e_learning/features/auth/presentaion/cubit/auth_cubit.dart';
import 'package:e_learning/features/auth/presentaion/cubit/auth_states.dart';
import 'package:e_learning/main_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:e_learning/core/constants/app_constants.dart';
import 'package:image_picker/image_picker.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  File? selectedImage;
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final phoneController = TextEditingController();
  bool acceptedTerms = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) setState(() => selectedImage = File(picked.path));
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              const SizedBox(height: 20),
              Text('Choose Photo', style: AppTextStyles.h2),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _ImageSourceTile(
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ImageSourceTile(
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _register() {
    if (!acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please accept the terms to continue'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    if (_formKey.currentState!.validate()) {
      context.read<AuthCubit>().register(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
            name: nameController.text.trim(),
            phone: phoneController.text.trim(),
            avatar: selectedImage,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is SignUpSuccess) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (_) => MainShell(userId: state.userId)),
            (_) => false,
          );
        }
        if (state is SignUpFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            // ── Decorative Top Background ──────────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 280,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      top: -30,
                      right: -30,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.07),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 60,
                      right: 40,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: -20,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Back Button ────────────────────────────────────────────────
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
            ),

            // ── Content ────────────────────────────────────────────────────
            SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 16),

                    // ── Avatar Picker ────────────────────────────────────────
                    FadeTransition(
                      opacity: _fadeAnim,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: _showImagePicker,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Outer ring
                                  Container(
                                    width: 110,
                                    height: 110,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white.withOpacity(0.5),
                                          width: 3),
                                    ),
                                  ),
                                  // Avatar
                                  CircleAvatar(
                                    radius: 50,
                                    backgroundColor:
                                        Colors.white.withOpacity(0.2),
                                    backgroundImage: selectedImage != null
                                        ? FileImage(selectedImage!)
                                        : null,
                                    child: selectedImage == null
                                        ? Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                Icons.add_a_photo_rounded,
                                                color: Colors.white,
                                                size: 28,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Add Photo',
                                                style: AppTextStyles.caption
                                                    .copyWith(
                                                        color: Colors.white70,
                                                        fontSize: 10),
                                              ),
                                            ],
                                          )
                                        : null,
                                  ),
                                  // Edit badge
                                  if (selectedImage != null)
                                    Positioned(
                                      bottom: 4,
                                      right: 4,
                                      child: Container(
                                        width: 28,
                                        height: 28,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.edit_rounded,
                                          size: 15,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Create Account ✨',
                              style: AppTextStyles.h1
                                  .copyWith(color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Start your learning journey today',
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Form Card ────────────────────────────────────────────
                    FadeTransition(
                      opacity: _fadeAnim,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.08),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Name + Phone row
                                Row(
                                  children: [
                                    Expanded(
                                      child: AppTextField(
                                        label: 'Full Name',
                                        hint: 'Ahmed Mohamed',
                                        prefixIcon:
                                            Icons.person_outline_rounded,
                                        controller: nameController,
                                        validator: (v) => v == null || v.isEmpty
                                            ? 'Required'
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                AppTextField(
                                  label: 'Phone Number',
                                  hint: '01012345678',
                                  prefixIcon: Icons.phone_outlined,
                                  controller: phoneController,
                                  keyboardType: TextInputType.phone,
                                  validator: (v) => v == null || v.isEmpty
                                      ? 'Required'
                                      : null,
                                ),
                                const SizedBox(height: 16),

                                AppTextField(
                                  label: 'Email Address',
                                  hint: 'you@example.com',
                                  prefixIcon: Icons.email_outlined,
                                  controller: emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) {
                                    if (v == null || v.isEmpty)
                                      return 'Required';
                                    if (!v.contains('@'))
                                      return 'Invalid email';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                AppTextField(
                                  label: 'Password',
                                  hint: '••••••••',
                                  prefixIcon: Icons.lock_outline_rounded,
                                  isPassword: true,
                                  controller: passwordController,
                                  validator: (v) {
                                    if (v == null || v.isEmpty)
                                      return 'Required';
                                    if (v.length < 6)
                                      return 'Min 6 characters';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                AppTextField(
                                  label: 'Confirm Password',
                                  hint: '••••••••',
                                  prefixIcon: Icons.lock_outline_rounded,
                                  isPassword: true,
                                  controller: confirmPasswordController,
                                  validator: (v) =>
                                      v != passwordController.text
                                          ? "Passwords don't match"
                                          : null,
                                ),
                                const SizedBox(height: 20),

                                // Terms
                                GestureDetector(
                                  onTap: () => setState(
                                      () => acceptedTerms = !acceptedTerms),
                                  child: Row(
                                    children: [
                                      AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          color: acceptedTerms
                                              ? AppColors.primary
                                              : Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                            color: acceptedTerms
                                                ? AppColors.primary
                                                : AppColors.cardBorder,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: acceptedTerms
                                            ? const Icon(Icons.check_rounded,
                                                color: Colors.white, size: 15)
                                            : null,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: RichText(
                                          text: TextSpan(
                                            style: AppTextStyles.bodySmall,
                                            children: [
                                              const TextSpan(
                                                  text: 'I agree to the '),
                                              TextSpan(
                                                text: 'Terms & Conditions',
                                                style: AppTextStyles.bodySmall
                                                    .copyWith(
                                                  color: AppColors.primary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Register Button
                                BlocBuilder<AuthCubit, AuthState>(
                                  builder: (context, state) {
                                    if (state is SignUpLoading) {
                                      return Container(
                                        height: 54,
                                        decoration: BoxDecoration(
                                          gradient:
                                              AppColors.primaryGradient,
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5),
                                        ),
                                      );
                                    }
                                    return AppPrimaryButton(
                                      label: 'Create Account',
                                      onTap: _register,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Sign In Link
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: RichText(
                        text: TextSpan(
                          text: 'Already have an account? ',
                          style: AppTextStyles.bodyMedium,
                          children: [
                            TextSpan(
                              text: 'Sign In',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Image Source Tile
// ─────────────────────────────────────────────
class _ImageSourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ImageSourceTile(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 32),
            const SizedBox(height: 8),
            Text(label,
                style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}