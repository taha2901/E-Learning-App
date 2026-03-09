// ─────────────────────────────────────────────
// quiz_model.dart  —  Data models only, no logic
// ─────────────────────────────────────────────

class QuizModel {
  final String id;
  final String videoId;
  final String courseId;
  final String title;
  final String description;
  final int passScore;
  final List<QuizQuestion> questions;

  QuizModel({
    required this.id,
    required this.videoId,
    required this.courseId,
    required this.title,
    required this.description,
    required this.passScore,
    required this.questions,
  });

  factory QuizModel.fromJson(Map<String, dynamic> json) => QuizModel(
        id: json['id'],
        videoId: json['video_id'] ?? '',
        courseId: json['course_id'] ?? '',
        title: json['title'] ?? 'Quick Quiz',
        description: json['description'] ?? '',
        passScore: json['pass_score'] ?? 70,
        questions: (json['quiz_questions'] as List<dynamic>? ?? [])
            .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex)),
      );
}

// ─────────────────────────────────────────────

class QuizQuestion {
  final String id;
  final String quizId;
  final String question;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String correctAnswer;
  final int orderIndex;

  QuizQuestion({
    required this.id,
    required this.quizId,
    required this.question,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.correctAnswer,
    required this.orderIndex,
  });

  /// Returns the option text for a given letter (a/b/c/d)
  String optionText(String letter) {
    switch (letter) {
      case 'a':
        return optionA;
      case 'b':
        return optionB;
      case 'c':
        return optionC;
      case 'd':
        return optionD;
      default:
        return '';
    }
  }

  factory QuizQuestion.fromJson(Map<String, dynamic> json) => QuizQuestion(
        id: json['id'],
        quizId: json['quiz_id'] ?? '',
        question: json['question'],
        optionA: json['option_a'],
        optionB: json['option_b'],
        optionC: json['option_c'],
        optionD: json['option_d'],
        correctAnswer: json['correct_answer'],
        orderIndex: json['order_index'] ?? 0,
      );
}

// ─────────────────────────────────────────────

class QuizResult {
  final String userId;
  final String quizId;
  final int score;
  final int total;
  final int percentage;
  final bool passed;

  QuizResult({
    required this.userId,
    required this.quizId,
    required this.score,
    required this.total,
    required this.percentage,
    required this.passed,
  });
}
