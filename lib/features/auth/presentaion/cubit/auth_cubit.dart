import 'dart:io';
import 'package:e_learning/features/auth/presentaion/cubit/auth_states.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repo/auth_repo.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepo repo;
  AuthCubit(this.repo) : super(AuthInitial());

  String? userId;
  String? userRole;

  Future<void> login({required String email, required String password}) async {
    emit(LoginLoading());
    final result = await repo.signIn(email: email, password: password);

    result.fold((error) => emit(LoginFailure(error)), (user) async {
      userId = user.id;
      final currentUser = repo.getCurrentUser();
      if (currentUser == null) {
        emit(LoginFailure("Unable to fetch user after login"));
        return;
      }
      userId = currentUser.id;

      final role = await repo.fetchUserRole(userId!);
      userRole = role;

      emit(LoginSuccess(userId!, role: role));
    });
  }

  Future<void> register({
    required String email,
    required String password,
    required String name,
    String? phone,
    File? avatar,
  }) async {
    emit(SignUpLoading());
    final result = await repo.signUp(email: email, password: password);
    result.fold((error) => emit(SignUpFailure(error)), (_) async {
      final user = repo.getCurrentUser();
      if (user == null) return emit(SignUpFailure("User not found"));
      String? avatarUrl;
      if (avatar != null) {
        avatarUrl = await repo.uploadAvatar(user.id, avatar);
      }
      await repo.createProfile(
        userId: user.id,
        name: name,
        phone: phone,
        avatarUrl: avatarUrl,
      );
      userId = user.id;
      emit(SignUpSuccess(userId!));
    });
  }

  Future<void> logout() async {
    await repo.logout();
    userId = null;
    userRole = null;
    emit(AuthInitial());
  }
}
