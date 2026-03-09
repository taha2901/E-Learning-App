import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/features/profile/data/models/certificate_data.dart';
import 'package:flutter/material.dart';

class CertificateInfoGrid extends StatelessWidget {
  final CertificateData data;
  final String dateStr;

  const CertificateInfoGrid({
    super.key,
    required this.data,
    required this.dateStr,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: InfoTile(
                icon: Icons.person_rounded,
                iconColor: AppColors.purple,
                label: 'Student',
                value: data.studentName,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InfoTile(
                icon: Icons.school_rounded,
                iconColor: AppColors.green,
                label: 'Course',
                value: data.courseName,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: InfoTile(
                icon: Icons.person_pin_rounded,
                iconColor: AppColors.gold,
                label: 'Instructor',
                value: data.instructorName,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InfoTile(
                icon: Icons.calendar_today_rounded,
                iconColor: AppColors.red,
                label: 'Completed',
                value: dateStr,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class InfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const InfoTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _TileIcon(icon: icon, color: iconColor),
          const SizedBox(width: 10),
          Expanded(child: _TileText(label: label, value: value)),
        ],
      ),
    );
  }
}

class _TileIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _TileIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }
}

class _TileText extends StatelessWidget {
  final String label;
  final String value;

  const _TileText({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.grey,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.dark,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}