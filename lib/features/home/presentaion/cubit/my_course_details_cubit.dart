import 'package:bloc/bloc.dart';
import 'package:e_learning/core/erros/app_exceptions.dart';
import 'package:e_learning/core/erros/network_exception_handler.dart';
import 'package:e_learning/features/courses/data/repo/course_repo.dart';
import 'package:e_learning/features/home/presentaion/cubit/my_course_details_states.dart';
import 'package:e_learning/features/quiz/data/repo/quiz_repo.dart';

class MyCourseDetailsCubit extends Cubit<MyCourseDetailsState> {
  final CoursesRepo _courseRepo;
  final QuizRepo _quizRepo;

  MyCourseDetailsCubit(this._courseRepo, this._quizRepo)
      : super(MyCourseDetailsInitial());

  /// بيتعمل call لما الـ screen تفتح
  /// بيجيب الـ watched videos + الـ quiz map في نفس الوقت (parallel)
  Future<void> loadData({
    required String userId,
    required String courseId,
  }) async {
    emit(MyCourseDetailsLoading());
    try {
      // بنشغل الاتنين مع بعض في نفس الوقت عشان متستناش واحدة تخلص الأول
      final results = await Future.wait([
        _courseRepo.fetchWatchedVideoIds(userId, courseId),
        _quizRepo.fetchAllQuizzes(),
      ]);

      final watchedIds = results[0] as Set<String>;
      final allQuizzes = results[1] as List;

      // بنعمل map من videoId → quizId للفيديوهات اللي عندها كويز وفيها أسئلة
      final videoQuizIdMap = <String, String>{};
      for (final quiz in allQuizzes) {
        if (quiz.questions.isNotEmpty) {
          videoQuizIdMap[quiz.videoId] = quiz.id;
        }
      }

      emit(MyCourseDetailsLoaded(
        watchedIds: watchedIds,
        videoQuizIdMap: videoQuizIdMap,
      ));
    } on AppException catch (e) {
      emit(MyCourseDetailsError(e));
    } catch (e) {
      emit(MyCourseDetailsError(NetworkExceptionHandler.handle(e)));
    }
  }

  /// بيتعمل call لما اليوزر يخلص الفيديو
  void markVideoWatched(String videoId) {
    if (state is! MyCourseDetailsLoaded) return;
    final s = state as MyCourseDetailsLoaded;
    emit(s.copyWith(watchedIds: {...s.watchedIds, videoId}));
  }
}
