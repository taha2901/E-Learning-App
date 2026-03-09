import 'dart:io';

import 'package:e_learning/core/erros/app_exceptions.dart';
import 'package:e_learning/core/erros/network_exception_handler.dart';
import 'package:e_learning/features/profile/data/repo/profile_repo.dart';
import 'package:e_learning/features/profile/presentation/cubit/profile_states.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileCubit extends Cubit<ProfileStates> {
  final ProfileRepo _repo;

  ProfileCubit(this._repo) : super(ProfileInitial());

  // ── Fetch ─────────────────────────────────────────────────
  Future<void> fetchUser(String userId) async {
    emit(ProfileLoading());
    try {
      final userData = await _repo.fetchUser(userId);
      emit(ProfileLoaded(userData));
    } on AppException catch (e) {
      emit(ProfileError(e.message));
    } catch (e) {
      emit(ProfileError(NetworkExceptionHandler.handle(e).message));
    }
  }

  // ── Update Profile ────────────────────────────────────────
  Future<void> updateProfile({
    required String userId,
    required String name,
    required String bio,
    String? phone,
  }) async {
    final previousState = state;
    try {
      await _repo.updateProfile(
        userId: userId,
        name: name,
        bio: bio,
        phone: phone,
      );
      await fetchUser(userId);
    } on AppException catch (e) {
      emit(ProfileError(e.message));
      await Future.delayed(const Duration(seconds: 2));
      if (!isClosed) emit(previousState);
    } catch (e) {
      emit(ProfileError(NetworkExceptionHandler.handle(e).message));
      await Future.delayed(const Duration(seconds: 2));
      if (!isClosed) emit(previousState);
    }
  }

  // ── Update Avatar ─────────────────────────────────────────
  Future<void> updateAvatar({
    required String userId,
    required File image,
  }) async {
    final previousState = state;
    try {
      await _repo.updateAvatar(userId: userId, image: image);
      await fetchUser(userId);
    } on AppException catch (e) {
      emit(ProfileError(e.message));
      await Future.delayed(const Duration(seconds: 2));
      if (!isClosed) emit(previousState);
    } catch (e) {
      emit(ProfileError(NetworkExceptionHandler.handle(e).message));
      await Future.delayed(const Duration(seconds: 2));
      if (!isClosed) emit(previousState);
    }
  }
}