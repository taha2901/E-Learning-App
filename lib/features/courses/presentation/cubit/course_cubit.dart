// courses_cubit.dart
import 'package:bloc/bloc.dart';
import 'package:e_learning/features/courses/data/repo/course_repo.dart';
import 'package:e_learning/features/courses/presentation/cubit/course_states.dart';
import 'package:e_learning/features/notificatio/data/model/notification_model.dart';
import 'package:e_learning/features/notificatio/data/repo/notification_repo.dart';

class CoursesCubit extends Cubit<CoursesState> {
  final CoursesRepo repo;
  final String userId;

  CoursesCubit(this.repo, this.userId) : super(CoursesInitial());

  void fetchMyCourses() async {
    emit(CoursesLoading());
    try {
      final courses = await repo.fetchMyCourses(userId);
      emit(CoursesLoaded(courses));
    } catch (e) {
      emit(CoursesError(e.toString()));
    }
  }

  Future<void> enrollCourse(String courseId) async {
    try {
      await repo.enrollInCourse(userId, courseId);

      // ✅ ابعت notification
      NotificationRepo().createNotification(
        userId: userId,
        title: '🎓 Enrolled Successfully!',
        body: 'You joined a new course. Start learning now!',
        type: NotificationType.course,
      );

      fetchMyCourses();
    } catch (e) {
      emit(CoursesError(e.toString()));
    }
  }
}
