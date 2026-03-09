import 'package:bloc/bloc.dart';
import 'package:e_learning/core/erros/app_exceptions.dart';
import 'package:e_learning/core/erros/network_exception_handler.dart';
import 'package:e_learning/features/quiz/data/model/quiz_model.dart';
import 'package:e_learning/features/quiz/data/repo/quiz_repo.dart';
import 'package:e_learning/features/home/presentaion/cubit/video_player_states.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VideoPlayerCubit extends Cubit<VideoPlayerState> {
  final QuizRepo _repo;

  VideoPlayerCubit(this._repo) : super(VideoPlayerInitial());

  /// بيتعمل call لما الـ VideoPlayerScreen تفتح
  /// بيجيب الكويز + النتيجة السابقة للـ user في نفس الوقت
  Future<void> loadQuizForVideo(String videoId) async {
    emit(VideoQuizLoading());
    try {
      final quiz = await _repo.fetchQuizForVideo(videoId);

      // لو مفيش كويز للفيديو ده خلاص انتهى
      if (quiz == null) {
        emit(VideoQuizLoaded(quiz: null));
        return;
      }

      // جيب النتيجة السابقة للـ user — لو فشل مش هنوقف، هنفتح الكويز عادي
      QuizResult? previousResult;
      try {
        final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
        if (userId.isNotEmpty) {
          previousResult = await _repo.fetchUserResult(userId, quiz.id);
        }
      } catch (_) {
        // silent — failure هنا معناها هنفتح الكويز من غير previous result
      }

      emit(VideoQuizLoaded(quiz: quiz, previousResult: previousResult));
    } on AppException catch (e) {
      emit(VideoQuizError(e));
    } catch (e) {
      emit(VideoQuizError(NetworkExceptionHandler.handle(e)));
    }
  }
}
