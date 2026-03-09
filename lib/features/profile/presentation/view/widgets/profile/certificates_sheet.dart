import 'package:e_learning/core/erros/app_error_widget.dart';
import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/features/profile/data/repo/certificate_repo.dart';
import 'package:e_learning/features/profile/presentation/cubit/certificate_cubit.dart';
import 'package:e_learning/features/profile/presentation/cubit/certificate_states.dart';
import 'package:e_learning/features/profile/presentation/view/certificate_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class CertificatesSheet extends StatelessWidget {
  final String userId;

  const CertificatesSheet({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          CertificateCubit(CertificateRepo())..fetchCertificates(userId),
      child: _CertificatesSheetBody(userId: userId),
    );
  }
}

class _CertificatesSheetBody extends StatelessWidget {
  final String userId;
  const _CertificatesSheetBody({required this.userId});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              const Icon(Icons.workspace_premium_outlined,
                  color: AppColors.warning),
              const SizedBox(width: 8),
              Text('My Certificates', style: AppTextStyles.h2),
            ]),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: BlocBuilder<CertificateCubit, CertificateState>(
              builder: (context, state) {
                if (state is CertificateLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is CertificateError) {
                  return AppErrorWidget(
                    exception: state.exception,
                    onRetry: () => context
                        .read<CertificateCubit>()
                        .fetchCertificates(userId),
                  );
                }

                if (state is CertificateLoaded) {
                  if (state.certificates.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.workspace_premium_outlined,
                              size: 56, color: AppColors.textHint),
                          const SizedBox(height: 12),
                          Text('No certificates yet',
                              style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary)),
                          const SizedBox(height: 6),
                          Text('Complete a course to earn one!',
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textHint)),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    itemCount: state.certificates.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 12),
                    itemBuilder: (ctx, i) {
                      final cert = state.certificates[i];
                      return _CertificateTile(
                        courseName: cert.courseName,
                        date: DateFormat('MMM d, yyyy')
                            .format(cert.completionDate),
                        onTap: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            ctx,
                            MaterialPageRoute(
                              builder: (_) =>
                                  CertificateScreen(data: cert),
                            ),
                          );
                        },
                      );
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
class _CertificateTile extends StatelessWidget {
  final String courseName;
  final String date;
  final VoidCallback onTap;

  const _CertificateTile({
    required this.courseName,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.workspace_premium_rounded,
                color: AppColors.warning, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(courseName,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('Completed $date',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded,
              size: 14, color: AppColors.textHint),
        ]),
      ),
    );
  }
}