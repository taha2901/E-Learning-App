import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:flutter/material.dart';

class RegisterPasswordStrengthBar extends StatelessWidget {
  final bool hasUppercase;
  final bool hasLowercase;
  final bool hasDigit;
  final bool hasMinLength;

  const RegisterPasswordStrengthBar({
    super.key,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasDigit,
    required this.hasMinLength,
  });

  int get _score =>
      (hasUppercase ? 1 : 0) +
      (hasLowercase ? 1 : 0) +
      (hasDigit ? 1 : 0) +
      (hasMinLength ? 1 : 0);

  Color get _barColor {
    if (_score <= 1) return AppColors.error;
    if (_score == 2) return AppColors.warning;
    if (_score == 3) return const Color(0xFF3B82F6);
    return AppColors.success;
  }

  String get _label {
    if (_score <= 1) return 'Weak';
    if (_score == 2) return 'Fair';
    if (_score == 3) return 'Good';
    return 'Strong';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: LinearProgressIndicator(
                  value: _score / 4,
                  minHeight: 4,
                  backgroundColor: AppColors.cardBorder,
                  valueColor: AlwaysStoppedAnimation(_barColor),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _label,
              style: AppTextStyles.caption.copyWith(
                color: _barColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            _PasswordRequirement(label: '8+ chars', met: hasMinLength),
            _PasswordRequirement(label: 'Uppercase', met: hasUppercase),
            _PasswordRequirement(label: 'Lowercase', met: hasLowercase),
            _PasswordRequirement(label: 'Number', met: hasDigit),
          ],
        ),
      ],
    );
  }
}

class _PasswordRequirement extends StatelessWidget {
  final String label;
  final bool met;

  const _PasswordRequirement({required this.label, required this.met});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          met
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          size: 13,
          color: met ? AppColors.success : AppColors.textHint,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: met ? AppColors.success : AppColors.textHint,
            fontWeight: met ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}