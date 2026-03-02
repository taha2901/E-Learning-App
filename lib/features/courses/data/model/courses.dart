// ─────────────────────────────────────────────
// Course Model
// ─────────────────────────────────────────────
class CourseModel {
  final String id;
  final String title;
  final String instructor;
  final String description;
  final String thumbnailUrl;
  final String category;
  final double rating;
  final int studentsCount;
  final int lessonsCount;
  final String duration;
  final String level;
  final bool isEnrolled;
  final List<VideoModel> videos;

  const CourseModel({
    required this.id,
    required this.title,
    required this.instructor,
    required this.description,
    required this.thumbnailUrl,
    required this.category,
    required this.rating,
    required this.studentsCount,
    required this.lessonsCount,
    required this.duration,
    required this.level,
    this.isEnrolled = false,
    this.videos = const [],
  });

  CourseModel copyWith({bool? isEnrolled}) {
    return CourseModel(
      id: id,
      title: title,
      instructor: instructor,
      description: description,
      thumbnailUrl: thumbnailUrl,
      category: category,
      rating: rating,
      studentsCount: studentsCount,
      lessonsCount: lessonsCount,
      duration: duration,
      level: level,
      isEnrolled: isEnrolled ?? this.isEnrolled,
      videos: videos,
    );
  }
}

// ─────────────────────────────────────────────
// Video Model
// ─────────────────────────────────────────────
class VideoModel {
  final String id;
  final String title;
  final String duration;
  final String videoUrl;
  final bool isWatched;
  final bool isLocked;

  const VideoModel({
    required this.id,
    required this.title,
    required this.duration,
    required this.videoUrl,
    this.isWatched = false,
    this.isLocked = false,
  });
}

// ─────────────────────────────────────────────
// User Model
// ─────────────────────────────────────────────
class UserModel {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final String bio;
  final int enrolledCoursesCount;
  final int completedCoursesCount;
  final int certificatesCount;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.bio,
    required this.enrolledCoursesCount,
    required this.completedCoursesCount,
    required this.certificatesCount,
  });
}



class MockData {
  // ── Videos ──────────────────────────────────
  static List<VideoModel> sampleVideos = const [
    VideoModel(
      id: 'v1',
      title: 'Introduction & Course Overview',
      duration: '5:30',
      videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      isWatched: true,
      isLocked: false,
    ),
    VideoModel(
      id: 'v2',
      title: 'Setting Up Your Environment',
      duration: '12:45',
      videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
      isWatched: true,
      isLocked: false,
    ),
    VideoModel(
      id: 'v3',
      title: 'Core Concepts Explained',
      duration: '18:20',
      videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
      isWatched: false,
      isLocked: false,
    ),
    VideoModel(
      id: 'v4',
      title: 'Building Your First Project',
      duration: '25:10',
      videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
      isWatched: false,
      isLocked: true,
    ),
    VideoModel(
      id: 'v5',
      title: 'Advanced Techniques',
      duration: '30:00',
      videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/SubaruOutbackOnStreetAndDirt.mp4',
      isWatched: false,
      isLocked: true,
    ),
  ];

  // ── Courses ──────────────────────────────────
  static List<CourseModel> courses = [
    CourseModel(
      id: 'c1',
      title: 'Flutter & Dart – The Complete Guide',
      instructor: 'Ahmed Kamal',
      description:
          'Master Flutter from scratch. Build beautiful cross-platform apps for iOS and Android with real-world projects and hands-on practice.',
      thumbnailUrl: 'https://picsum.photos/seed/flutter/400/220',
      category: 'Mobile Dev',
      rating: 4.8,
      studentsCount: 12400,
      lessonsCount: 42,
      duration: '28h 30m',
      level: 'Beginner',
      isEnrolled: true,
      videos: sampleVideos,
    ),
    CourseModel(
      id: 'c2',
      title: 'UI/UX Design Fundamentals',
      instructor: 'Sara Hassan',
      description:
          'Learn the principles of great UX design. Create wireframes, prototypes, and user flows that delight users and achieve business goals.',
      thumbnailUrl: 'https://picsum.photos/seed/uiux/400/220',
      category: 'Design',
      rating: 4.9,
      studentsCount: 8200,
      lessonsCount: 30,
      duration: '18h 45m',
      level: 'Intermediate',
      isEnrolled: false,
      videos: sampleVideos,
    ),
    CourseModel(
      id: 'c3',
      title: 'Python for Data Science',
      instructor: 'Omar Youssef',
      description:
          'Dive into data science using Python. Explore pandas, matplotlib, scikit-learn, and real datasets to build powerful analytical skills.',
      thumbnailUrl: 'https://picsum.photos/seed/python/400/220',
      category: 'Data Science',
      rating: 4.7,
      studentsCount: 15600,
      lessonsCount: 55,
      duration: '35h 00m',
      level: 'Beginner',
      isEnrolled: true,
      videos: sampleVideos,
    ),
    CourseModel(
      id: 'c4',
      title: 'React.js – Build Modern Web Apps',
      instructor: 'Mona Tarek',
      description:
          'Go from zero to hero with React. Build production-ready web applications using hooks, Redux, and modern JS patterns.',
      thumbnailUrl: 'https://picsum.photos/seed/react/400/220',
      category: 'Web Dev',
      rating: 4.6,
      studentsCount: 9800,
      lessonsCount: 38,
      duration: '22h 10m',
      level: 'Intermediate',
      isEnrolled: false,
      videos: sampleVideos,
    ),
    CourseModel(
      id: 'c5',
      title: 'Machine Learning A–Z',
      instructor: 'Khaled Nour',
      description:
          'A comprehensive ML course covering supervised learning, neural networks, NLP and deployment strategies with practical exercises.',
      thumbnailUrl: 'https://picsum.photos/seed/ml/400/220',
      category: 'AI & ML',
      rating: 4.9,
      studentsCount: 21000,
      lessonsCount: 70,
      duration: '45h 20m',
      level: 'Advanced',
      isEnrolled: false,
      videos: sampleVideos,
    ),
    CourseModel(
      id: 'c6',
      title: 'Node.js & Express – Backend Mastery',
      instructor: 'Youssef Ali',
      description:
          'Build powerful REST APIs and backend services with Node.js, Express, MongoDB, and authentication systems.',
      thumbnailUrl: 'https://picsum.photos/seed/nodejs/400/220',
      category: 'Web Dev',
      rating: 4.5,
      studentsCount: 6700,
      lessonsCount: 34,
      duration: '20h 00m',
      level: 'Intermediate',
      isEnrolled: true,
      videos: sampleVideos,
    ),
  ];

  // ── User ──────────────────────────────────────
  static const UserModel currentUser = UserModel(
    id: 'u1',
    name: 'Ahmed Mohamed',
    email: 'ahmed.mohamed@example.com',
    avatarUrl: 'https://picsum.photos/seed/user1/200/200',
    bio: 'Passionate developer & lifelong learner. Building great apps one line at a time.',
    enrolledCoursesCount: 3,
    completedCoursesCount: 1,
    certificatesCount: 1,
  );
}