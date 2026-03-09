// screens/notifications_screen.dart

import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/features/notificatio/presentation/logic/notification_cubit.dart';
import 'package:e_learning/features/notificatio/presentation/logic/notification_states.dart';
import 'package:e_learning/features/notificatio/presentation/view/widgets/notifications_app_bar.dart';
import 'package:e_learning/features/notificatio/presentation/view/widgets/notifications_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationCubit, NotificationState>(
      builder: (context, state) {
        final cubit = context.read<NotificationCubit>();

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: NotificationsAppBar(state: state, cubit: cubit),
          body: NotificationsBody(state: state, cubit: cubit),
        );
      },
    );
  }
}