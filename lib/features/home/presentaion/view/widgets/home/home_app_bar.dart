import 'package:e_learning/core/constants/app_constants.dart';
import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeAppBar extends StatelessWidget {
  const HomeAppBar({super.key});

  Future<Map<String, dynamic>?> _fetchAvatar(String userId) async {
    if (userId.isEmpty) return null;
    try {
      return await Supabase.instance.client
          .from('profiles')
          .select('avatar_url')
          .eq('user_id', userId)
          .maybeSingle();
    } catch (_) {
      return null;
    }
  }

  Widget _avatarFallback(String name) => Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'U',
          style: AppTextStyles.h3.copyWith(
              color: AppColors.primary, fontWeight: FontWeight.w700),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final meta = user?.userMetadata;
    final name =
        meta?['name'] as String? ?? user?.email?.split('@').first ?? 'there';
    final firstName = name.split(' ').first;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppConstants.horizontalPadding,
          20,
          AppConstants.horizontalPadding,
          0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, $firstName 👋',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text('What will you\nlearn today?', style: AppTextStyles.h1),
              ],
            ),
          ),
          FutureBuilder<Map<String, dynamic>?>(
            future: _fetchAvatar(user?.id ?? ''),
            builder: (ctx, snap) {
              final avatarUrl = snap.data?['avatar_url'] as String? ?? '';
              return Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.3), width: 2),
                  color: AppColors.primary.withOpacity(0.08),
                ),
                child: ClipOval(
                  child: avatarUrl.isNotEmpty
                      ? Image.network(avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _avatarFallback(firstName))
                      : _avatarFallback(firstName),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}