
import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:flutter/material.dart';

class OptionTile extends StatelessWidget {
  final String letter;
  final String text;
  final bool selected;
  final bool correct;
  final bool wrong;
  final VoidCallback onTap;

  const OptionTile({
    super.key,
    required this.letter,
    required this.text,
    required this.selected,
    required this.correct,
    required this.wrong,
    required this.onTap,
  });

  // Derive visual state once so we don't repeat logic
  _OptionStyle get _style {
    if (correct) return _OptionStyle.correct();
    if (wrong)   return _OptionStyle.wrong();
    if (selected) return _OptionStyle.selected();
    return _OptionStyle.idle();
  }

  @override
  Widget build(BuildContext context) {
    final s = _style;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: s.bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: s.borderColor, width: 1.5),
        ),
        child: Row(
          children: [
            _LetterBadge(letter: letter, bg: s.letterBg, fg: s.letterFg),
            const SizedBox(width: 14),
            Expanded(child: Text(text, style: AppTextStyles.bodyLarge)),
            if (s.trailingIcon != null) ...[
              const SizedBox(width: 8),
              s.trailingIcon!,
            ],
          ],
        ),
      ),
    );
  }
}

class _LetterBadge extends StatelessWidget {
  final String letter;
  final Color bg;
  final Color fg;

  const _LetterBadge({required this.letter, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          letter.toUpperCase(),
          style: AppTextStyles.h3.copyWith(color: fg),
        ),
      ),
    );
  }
}

// ── Value object holding all visual properties for one state ──────────────────
class _OptionStyle {
  final Color borderColor;
  final Color bgColor;
  final Color letterBg;
  final Color letterFg;
  final Widget? trailingIcon;

  const _OptionStyle({
    required this.borderColor,
    required this.bgColor,
    required this.letterBg,
    required this.letterFg,
    this.trailingIcon,
  });

  factory _OptionStyle.idle() => _OptionStyle(
        borderColor: AppColors.cardBorder,
        bgColor: AppColors.surface,
        letterBg: AppColors.surfaceVariant,
        letterFg: AppColors.textSecondary,
      );

  factory _OptionStyle.selected() => _OptionStyle(
        borderColor: AppColors.primary,
        bgColor: AppColors.primary.withOpacity(0.06),
        letterBg: AppColors.primary,
        letterFg: Colors.white,
      );

  factory _OptionStyle.correct() => _OptionStyle(
        borderColor: AppColors.success,
        bgColor: AppColors.success.withOpacity(0.06),
        letterBg: AppColors.success,
        letterFg: Colors.white,
        trailingIcon: const Icon(Icons.check_circle_rounded,
            color: AppColors.success, size: 22),
      );

  factory _OptionStyle.wrong() => _OptionStyle(
        borderColor: AppColors.error,
        bgColor: AppColors.error.withOpacity(0.06),
        letterBg: AppColors.error,
        letterFg: Colors.white,
        trailingIcon: const Icon(Icons.cancel_rounded,
            color: AppColors.error, size: 22),
      );
}