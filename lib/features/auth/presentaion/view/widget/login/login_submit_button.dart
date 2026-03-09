import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/widgets/custom_btn.dart';
import 'package:e_learning/features/auth/presentaion/cubit/auth_cubit.dart';
import 'package:e_learning/features/auth/presentaion/cubit/auth_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginSubmitButton extends StatelessWidget {
  final VoidCallback onTap;

  const LoginSubmitButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is LoginLoading) {
          return Container(
            height: 54,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            ),
          );
        }
        return AppPrimaryButton(
          label: 'Sign In',
          onTap: onTap,
        );
      },
    );
  }
}