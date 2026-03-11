import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api/api_client.dart';
import 'auth/auth_repository.dart';
import 'auth/models.dart';
import 'auth/token_store.dart';
import 'config.dart';
import '../features/courses/courses_repository.dart';
import '../features/courses/models.dart';
import '../features/timeline/timeline_repository.dart';
import '../features/timeline/models.dart';
import '../features/assignments/assignments_repository.dart';
import '../features/announcements_exams/repository.dart';
import '../features/announcements_exams/models.dart';

final coursesRepositoryProvider = Provider<CoursesRepository>((ref) {
  return CoursesRepository(ref.watch(apiClientProvider));
});

final coursesProvider = FutureProvider<List<Course>>((ref) async {
  final auth = ref.watch(authStateNotifierProvider);
  if (!auth.isAuthed) return const [];
  final repo = ref.watch(coursesRepositoryProvider);
  return repo.listCourses(batchId: auth.user!.batchId);
});

final timelineRepositoryProvider = Provider<TimelineRepository>((ref) {
  return TimelineRepository(ref.watch(apiClientProvider));
});

final assignmentsRepositoryProvider = Provider<AssignmentsRepository>((ref) {
  return AssignmentsRepository(ref.watch(apiClientProvider));
});

final announcementsExamsRepositoryProvider =
    Provider<AnnouncementsExamsRepository>((ref) {
  return AnnouncementsExamsRepository(ref.watch(apiClientProvider));
});

final activeCourseIdProvider = StateProvider<String?>((ref) => null);

final timelineProvider = FutureProvider<TimelineBundle>((ref) async {
  final auth = ref.watch(authStateNotifierProvider);
  if (!auth.isAuthed) return const TimelineBundle(assignments: [], announcements: []);
  final courseId = ref.watch(activeCourseIdProvider);
  final repo = ref.watch(timelineRepositoryProvider);
  return repo.fetch(courseId: courseId);
});

final gpaProvider = Provider<double?>((ref) {
  final courses = ref.watch(coursesProvider);
  final timeline = ref.watch(timelineProvider);
  final coursesData = courses.valueOrNull;
  final timelineData = timeline.valueOrNull;
  if (coursesData == null || timelineData == null) return null;

  final courseMap = {for (final c in coursesData) c.id: c};

  // Compute course percent from graded assignments.
  final byCourse = <String, List<int>>{};
  final weightedByCourse = <String, ({int sumWeighted, int sumWeight})>{};

  for (final a in timelineData.assignments) {
    final grade = a.gradePct;
    if (grade == null) continue;
    final w = a.weight ?? 0;
    if (w > 0) {
      final prev = weightedByCourse[a.course.id];
      final next = (
        sumWeighted: (prev?.sumWeighted ?? 0) + grade * w,
        sumWeight: (prev?.sumWeight ?? 0) + w,
      );
      weightedByCourse[a.course.id] = next;
    } else {
      (byCourse[a.course.id] ??= []).add(grade);
    }
  }

  double totalPoints = 0;
  int totalCredits = 0;

  for (final entry in courseMap.entries) {
    final courseId = entry.key;
    final course = entry.value;

    double? pct;
    final w = weightedByCourse[courseId];
    if (w != null && w.sumWeight > 0) {
      pct = w.sumWeighted / w.sumWeight;
    } else {
      final list = byCourse[courseId];
      if (list != null && list.isNotEmpty) {
        pct = list.reduce((a, b) => a + b) / list.length;
      }
    }
    if (pct == null) continue;

    final points = _pctToGpa(pct);
    totalPoints += points * course.credits;
    totalCredits += course.credits;
  }

  if (totalCredits == 0) return null;
  return totalPoints / totalCredits;
});

/// Per-course percentage used for the Grades tab UI.
final courseGradesProvider =
    Provider<List<({Course course, double percent})>>((ref) {
  final courses = ref.watch(coursesProvider);
  final timeline = ref.watch(timelineProvider);
  final coursesData = courses.valueOrNull;
  final timelineData = timeline.valueOrNull;
  if (coursesData == null || timelineData == null) return const [];

  final byCourse = <String, List<int>>{};
  final weightedByCourse = <String, ({int sumWeighted, int sumWeight})>{};

  for (final a in timelineData.assignments) {
    final grade = a.gradePct;
    if (grade == null) continue;
    final w = a.weight ?? 0;
    if (w > 0) {
      final prev = weightedByCourse[a.course.id];
      final next = (
        sumWeighted: (prev?.sumWeighted ?? 0) + grade * w,
        sumWeight: (prev?.sumWeight ?? 0) + w,
      );
      weightedByCourse[a.course.id] = next;
    } else {
      (byCourse[a.course.id] ??= []).add(grade);
    }
  }

  final rows = <({Course course, double percent})>[];

  for (final course in coursesData) {
    double? pct;
    final w = weightedByCourse[course.id];
    if (w != null && w.sumWeight > 0) {
      pct = w.sumWeighted / w.sumWeight;
    } else {
      final list = byCourse[course.id];
      if (list != null && list.isNotEmpty) {
        pct = list.reduce((a, b) => a + b) / list.length;
      }
    }
    if (pct == null) continue;
    rows.add((course: course, percent: pct));
  }

  rows.sort((a, b) => a.course.code.compareTo(b.course.code));
  return rows;
});

double _pctToGpa(double pct) {
  if (pct >= 93) return 4.0;
  if (pct >= 90) return 3.7;
  if (pct >= 87) return 3.3;
  if (pct >= 83) return 3.0;
  if (pct >= 80) return 2.7;
  if (pct >= 77) return 2.3;
  if (pct >= 73) return 2.0;
  if (pct >= 70) return 1.7;
  if (pct >= 67) return 1.3;
  if (pct >= 65) return 1.0;
  return 0.0;
}

final announcementsProvider = FutureProvider<List<Announcement>>((ref) async {
  final auth = ref.watch(authStateNotifierProvider);
  if (!auth.isAuthed) return const [];
  final repo = ref.watch(announcementsExamsRepositoryProvider);
  return repo.listAnnouncements(auth.user!.batchId);
});

final examsProvider = FutureProvider<List<Exam>>((ref) async {
  final auth = ref.watch(authStateNotifierProvider);
  if (!auth.isAuthed) return const [];
  final repo = ref.watch(announcementsExamsRepositoryProvider);
  return repo.listExams(auth.user!.batchId);
});

final isAndroidEmulatorProvider = Provider<bool>((ref) {
  // Heuristic: if running on Android, assume emulator for dev.
  // For a real device you can flip this later or make it configurable.
  return !kIsWeb && Platform.isAndroid;
});

final baseUrlProvider = Provider<String>((ref) {
  final isAndroidEmu = ref.watch(isAndroidEmulatorProvider);
  return AppConfig.apiBaseUrlForPlatform(isAndroidEmulator: isAndroidEmu);
});

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final tokenStoreProvider = Provider<TokenStore>((ref) {
  return TokenStore(ref.watch(secureStorageProvider));
});

final authStateNotifierProvider =
    NotifierProvider<AuthStateNotifier, AuthState>(AuthStateNotifier.new);

final apiClientProvider = Provider<ApiClient>((ref) {
  final baseUrl = ref.watch(baseUrlProvider);
  final token = ref.watch(authStateNotifierProvider).token;
  return ApiClient(baseUrl: baseUrl, token: token);
});

class AuthStateNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _restore();
    return AuthState.signedOut;
  }

  Future<void> _restore() async {
    final store = ref.read(tokenStoreProvider);
    final token = await store.readToken();
    if (token == null) return;

    final baseUrl = ref.read(baseUrlProvider);
    final repo = AuthRepository(ApiClient(baseUrl: baseUrl, token: token));

    try {
      final user = await repo.me();
      state = AuthState(token: token, user: user);
    } catch (_) {
      await store.clear();
      state = AuthState.signedOut;
    }
  }

  Future<void> login(String email, String password) async {
    final baseUrl = ref.read(baseUrlProvider);
    final repo = AuthRepository(ApiClient(baseUrl: baseUrl));
    final (token, user) = await repo.login(email: email, password: password);
    await ref.read(tokenStoreProvider).writeToken(token);
    state = AuthState(token: token, user: user);
  }

  Future<void> logout() async {
    await ref.read(tokenStoreProvider).clear();
    state = AuthState.signedOut;
  }
}

