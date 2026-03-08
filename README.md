# 📚 EduLearn — Flutter E-Learning App

<p align="center">
  <img src="assets/images/image.png" width="500" alt="App Icon"/>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white"/>
  <img src="https://img.shields.io/badge/Supabase-Backend-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white"/>
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white"/>
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey?style=for-the-badge"/>
</p>

---

## ✨ Overview

**EduLearn** is a full-featured mobile e-learning platform built with Flutter and powered by Supabase. It allows users to browse, enroll in, and complete courses — with a rich admin panel for content management.

---


## 🚀 Features

### 👤 Authentication
- Email & password sign up / sign in
- Persistent session with Supabase Auth
- Profile management (name, avatar, bio)

---

### 🎓 Courses
- Browse all available courses
- Filter by category (Mobile Dev, Web Dev, Design, Data Science, AI & ML)
- Featured courses section
- Course details with instructor info, rating, duration & level
- Enroll in courses for free

---

### 🎬 Video Player
- Stream videos directly in-app
- YouTube video support
- Track watch progress per video
- Mark videos as watched at 90% completion
- Locked videos 🔒 — only accessible after enrollment

---

### 📝 Quizzes
- Quiz attached to each video lesson
- Previous result check before retaking
- Retake flow via bottom sheet
- Notification on quiz completion

---

### 🔖 Wishlist
- Save/unsave courses to wishlist
- Persistent across sessions

---

### ⭐ Ratings & Reviews
- Rate courses (1–5 stars)
- Leave text reviews
- View all reviews per course

---

### 🏆 Certificate Generation
- Certificate auto-generated on course completion
- Download as **PDF** or **PNG** directly to device
- Personalized with student name, course title & date

---

### 🔔 Notifications
- In-app notification banner
- Triggered on:
  - Course completion
  - Quiz passed/failed

---

### 👤 Profile
- Edit personal info (name, email, avatar)
- View enrolled courses & progress
- View earned certificates
- Notification history

---

### 🛡️ Admin Panel
- **Course Management:** Add, edit, delete courses
- **Video Management:** Add single videos or import full YouTube playlists
- **Quiz Management:** Attach quizzes to specific videos
- **Thumbnail Picker:** Upload from gallery or paste URL
- Featured course toggle
- Optimistic UI with rollback on error

---

## 🏗️ Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.x |
| Language | Dart 3.x |
| Backend | Supabase (Auth, Database, Storage) |
| State Management | Flutter BLoC / Cubit |
| Video Playback | `video_player` + `chewie` |
| YouTube Support | `youtube_player_flutter` |
| PDF Generation | `pdf` + `printing` |
| Image Picker | `image_picker` |
| Notifications | Custom banner service |
| Fonts | Poppins |

---

## 🗄️ Database Schema

```
courses
├── id, title, category, instructor
├── description, thumbnail_url
├── rating, students_count, lessons_count
├── duration, level, is_featured

videos
├── id, course_id, title
├── video_url, duration
├── is_locked, is_watched

enrollments
├── id, user_id, course_id, enrolled_at

video_progress
├── id, user_id, video_id, is_watched

quizzes
├── id, video_id, questions (JSON)

reviews
├── id, user_id, course_id, rating, comment

wishlist
├── id, user_id, course_id

certificates
├── id, user_id, course_id, issued_at

profiles
├── id, full_name, avatar_url, bio
```

---

## ⚙️ Setup & Installation

### Prerequisites
- Flutter SDK `^3.11.0`
- Dart SDK `^3.11.0`
- Supabase project

### 1. Clone the repo
```bash
git clone https://github.com/taha2901/E-Learning-App.git
cd e_learning
```

### 2. Install dependencies
```bash
flutter pub get
```


### 5. Run the app
```bash
flutter run
```

---

## 📦 Key Dependencies

```yaml
flutter_bloc: ^9.1.1
supabase_flutter: ^2.12.0
video_player: ^2.11.0
chewie: ^1.13.0
youtube_player_flutter: ^9.1.3
image_picker: ^1.2.1
pdf: ^3.11.3
printing: ^5.14.2
share_plus: ^12.0.1
http: ^1.2.0
```

---

## 📁 Project Structure

```
lib/
├── core/
│   ├── errors/          # AppException, ErrorWidget, NetworkHandler
│   ├── theme/           # AppColors, TextStyles
│   └── constants/       # Supabase config
├── features/
│   ├── auth/            # Login, Register screens + Cubit
│   ├── courses/
│   │   ├── data/        # CourseModel, VideoModel, CoursesRepo
│   │   ├── logic/       # CoursesCubit, HomeCubit, WishlistCubit
│   │   └── presentation/
│   │       ├── home_screen.dart
│   │       ├── courses_details.dart
│   │       └── vedio_player_screen.dart
│   ├── admin/
│   │   └── admin_courses_screen.dart
│   └── profile/         # ProfileScreen, CertificatesScreen
└── main.dart
```

---

## 🔐 Supabase RLS Policies

Run in SQL Editor:

```sql
-- Videos: cascade delete progress on video delete
ALTER TABLE video_progress
ADD CONSTRAINT video_progress_video_id_fkey
FOREIGN KEY (video_id) REFERENCES videos(id) ON DELETE CASCADE;

-- Storage: allow authenticated upload
CREATE POLICY "Allow upload" ON storage.objects
FOR INSERT TO authenticated WITH CHECK (bucket_id = 'course-images');

CREATE POLICY "Allow read" ON storage.objects
FOR SELECT TO public USING (bucket_id = 'course-images');
```

---

## 🤝 Contributing

Pull requests are welcome! For major changes, please open an issue first.

---


<p align="center">Made with Taha Hamada using Flutter & Supabase</p>




