import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/features/profile/data/models/certificate_data.dart';
import 'package:flutter/material.dart';

class CertificateCard extends StatelessWidget {
  final CertificateData data;
  final String dateStr;

  const CertificateCard({
    super.key,
    required this.data,
    required this.dateStr,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF4A42CC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withOpacity(.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _GoldDividerLine(),
          const SizedBox(height: 16),
          _CardLogo(),
          const SizedBox(height: 12),
          _CardTitle(),
          const SizedBox(height: 16),
          const Text(
            'This is to proudly certify that',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 10),
          _StudentNamePill(name: data.studentName),
          const SizedBox(height: 10),
          const Text(
            'has successfully completed',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            data.courseName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          Divider(color: Colors.white.withOpacity(.25)),
          const SizedBox(height: 12),
          _CardFooterRow(
            dateStr: dateStr,
            instructorName: data.instructorName,
          ),
          const SizedBox(height: 14),
          Text(
            'ID: ${data.certificateId}',
            style: TextStyle(
              color: Colors.white.withOpacity(.45),
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Private sub-widgets ──────────────────────────────────────────────────────

class _GoldDividerLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 3,
      decoration: BoxDecoration(
        color: AppColors.gold,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _CardLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.2),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: Colors.white.withOpacity(.5),
              width: 1,
            ),
          ),
          child: const Text(
            'L',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'LearnFlow',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _CardTitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text(
          'CERTIFICATE',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        Text(
          'OF COMPLETION',
          style: TextStyle(
            color: AppColors.gold,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 4,
          ),
        ),
      ],
    );
  }
}

class _StudentNamePill extends StatelessWidget {
  final String name;

  const _StudentNamePill({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.15),
        border: Border.all(color: Colors.white.withOpacity(.4), width: 1.5),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Text(
        name,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _CardFooterRow extends StatelessWidget {
  final String dateStr;
  final String instructorName;

  const _CardFooterRow({
    required this.dateStr,
    required this.instructorName,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _CardBottomItem(label: 'Completion', value: dateStr),
        _VerifiedBadge(),
        _CardBottomItem(label: 'Instructor', value: instructorName),
      ],
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.green.withOpacity(.15),
            border: const Border.fromBorderSide(
              BorderSide(color: AppColors.green, width: 2),
            ),
          ),
          child: const Icon(
            Icons.verified_rounded,
            color: AppColors.green,
            size: 22,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'VERIFIED',
          style: TextStyle(
            color: AppColors.green,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _CardBottomItem extends StatelessWidget {
  final String label;
  final String value;

  const _CardBottomItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(.6),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}