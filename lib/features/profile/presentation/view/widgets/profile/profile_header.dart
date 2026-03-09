// widgets/profile_header.dart

import 'package:e_learning/core/constants/app_constants.dart';
import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  final Map<String, dynamic> user;
  final String userId;
  final VoidCallback onEditTap;
  final VoidCallback onAvatarTap;

  const ProfileHeader({
    super.key,
    required this.user,
    required this.userId,
    required this.onEditTap,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatarUrl = user['avatar_url']?.toString() ?? '';
    final name      = user['name']?.toString() ?? '';
    final email     = user['email']?.toString() ?? '';
    final bio       = user['bio']?.toString() ?? '';
    final phone     = user['phone']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.horizontalPadding, 0,
        AppConstants.horizontalPadding, 28,
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            _HeaderTopBar(onEditTap: onEditTap),
            const SizedBox(height: 24),
            _AvatarWidget(
              avatarUrl: avatarUrl,
              name: name,
              onTap: onAvatarTap,
            ),
            const SizedBox(height: 16),
            Text(name, style: AppTextStyles.h1),
            const SizedBox(height: 4),
            Text(
              email,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.primary),
            ),
            if (phone.isNotEmpty) ...[
              const SizedBox(height: 4),
              _PhoneRow(phone: phone),
            ],
            if (bio.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                bio,
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeaderTopBar extends StatelessWidget {
  final VoidCallback onEditTap;
  const _HeaderTopBar({required this.onEditTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Profile', style: AppTextStyles.h1),
        IconButton(
          icon: const Icon(Icons.settings_outlined,
              color: AppColors.textPrimary),
          onPressed: () {},
        ),
      ],
    );
  }
}

class _AvatarWidget extends StatelessWidget {
  final String avatarUrl;
  final String name;
  final VoidCallback onTap;

  const _AvatarWidget({
    required this.avatarUrl,
    required this.name,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            backgroundImage:
                avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
            child: avatarUrl.isEmpty
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                    style: AppTextStyles.h1
                        .copyWith(color: AppColors.primary),
                  )
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.camera_alt_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhoneRow extends StatelessWidget {
  final String phone;
  const _PhoneRow({required this.phone});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.phone_outlined,
            size: 14, color: AppColors.textHint),
        const SizedBox(width: 4),
        Text(
          phone,
          style: AppTextStyles.bodySmall
              .copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}