import 'package:e_learning/core/erros/app_exceptions.dart';

abstract class MyCourseDetailsState {}

class MyCourseDetailsInitial extends MyCourseDetailsState {}

class MyCourseDetailsLoading extends MyCourseDetailsState {}

/// البيانات اتحملت — progress + quiz map
class MyCourseDetailsLoaded extends MyCourseDetailsState {
  final Set<String> watchedIds;

  /// map من videoId → quizId — عشان نعرف الفيديو ده عنده كويز ولا لأ
  final Map<String, String> videoQuizIdMap;

  MyCourseDetailsLoaded({
    required this.watchedIds,
    required this.videoQuizIdMap,
  });

  MyCourseDetailsLoaded copyWith({
    Set<String>? watchedIds,
    Map<String, String>? videoQuizIdMap,
  }) {
    return MyCourseDetailsLoaded(
      watchedIds: watchedIds ?? this.watchedIds,
      videoQuizIdMap: videoQuizIdMap ?? this.videoQuizIdMap,
    );
  }
}

class MyCourseDetailsError extends MyCourseDetailsState {
  final AppException exception;
  MyCourseDetailsError(this.exception);
}
