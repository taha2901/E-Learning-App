import 'package:bloc/bloc.dart';
import 'package:e_learning/features/courses/data/model/courses.dart';
import 'package:e_learning/features/courses/data/repo/course_repo.dart';
import 'package:e_learning/features/home/presentaion/cubit/home_states.dart';

class HomeCubit extends Cubit<HomeState> {
  final CoursesRepo repo;
  HomeCubit(this.repo) : super(HomeInitial());

  Future<void> fetchCourses() async {
    emit(HomeLoading());
    try {
      final courses = await repo.fetchCourses();
      final featured = courses.where((c) => c.isFeatured).toList();
      emit(HomeLoaded(
        courses: courses,
        featuredCourses: featured,
        selectedCategory: 'All',
        searchQuery: '',
      ));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  void selectCategory(String category) {
    if (state is HomeLoaded) {
      emit((state as HomeLoaded).copyWith(selectedCategory: category));
    }
  }

  void searchCourses(String query) {
    if (state is HomeLoaded) {
      emit((state as HomeLoaded).copyWith(searchQuery: query));
    }
  }

  List<CourseModel> get filteredCourses {
    if (state is! HomeLoaded) return [];
    final s = state as HomeLoaded;
    return s.courses.where((c) {
      final matchCat =
          s.selectedCategory == 'All' || c.category == s.selectedCategory;
      final matchSearch =
          c.title.toLowerCase().contains(s.searchQuery.toLowerCase());
      return matchCat && matchSearch;
    }).toList();
  }
}