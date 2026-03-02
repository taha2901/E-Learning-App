import 'package:e_learning/features/courses/data/model/courses.dart';
import 'package:flutter/material.dart';
class HomeViewModel extends ChangeNotifier {
  List<CourseModel> _allCourses = MockData.courses;
  List<CourseModel> _filteredCourses = MockData.courses;
  String _selectedCategory = 'All';
  String _searchQuery = '';

  List<CourseModel> get courses => _filteredCourses;
  String get selectedCategory => _selectedCategory;

  final List<String> categories = [
    'All',
    'Mobile Dev',
    'Web Dev',
    'Design',
    'Data Science',
    'AI & ML',
  ];

  void onSearchChanged(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void onCategorySelected(String category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    // TODO: Implement filter logic
    notifyListeners();
  }
}