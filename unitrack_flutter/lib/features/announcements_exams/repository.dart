import '../../core/api/api_client.dart';
import 'models.dart';

class AnnouncementsExamsRepository {
  final ApiClient _api;

  AnnouncementsExamsRepository(this._api);

  Future<List<Announcement>> listAnnouncements(String batchId) async {
    final res = await _api.dio
        .get<Map<String, dynamic>>('/batches/$batchId/announcements');
    final items =
        (res.data!['announcements'] as List).cast<Map<String, dynamic>>();
    return items.map(Announcement.fromJson).toList();
  }

  Future<void> createAnnouncement({
    required String batchId,
    required String title,
    required String body,
  }) async {
    await _api.dio.post(
      '/batches/$batchId/announcements',
      data: {'title': title, 'body': body},
    );
  }

  Future<List<Exam>> listExams(String batchId) async {
    final res =
        await _api.dio.get<Map<String, dynamic>>('/batches/$batchId/exams');
    final items = (res.data!['exams'] as List).cast<Map<String, dynamic>>();
    return items.map(Exam.fromJson).toList();
  }

  Future<void> createExam({
    required String batchId,
    required String courseId,
    required String kind,
    required DateTime startsAt,
    String? location,
    String? notes,
  }) async {
    await _api.dio.post(
      '/batches/$batchId/exams',
      data: {
        'courseId': courseId,
        'kind': kind,
        'startsAt': startsAt.toUtc().toIso8601String(),
        if (location != null && location.isNotEmpty) 'location': location,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
  }
}

