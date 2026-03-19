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

  Future<void> deleteAnnouncement({
    required String batchId,
    required String id,
  }) async {
    await _api.dio.delete('/batches/$batchId/announcements/$id');
  }

  Future<({String summary, List<String> keyPoints, List<String> dates})?>
      summarizeAnnouncement({
    required String batchId,
    required String id,
  }) async {
    try {
      final res = await _api.dio.post<Map<String, dynamic>>(
        '/batches/$batchId/announcements/$id/summary',
      );
      final data = res.data?['summary'] as Map<String, dynamic>?;
      if (data == null) return null;
      final summary = data['summary'] as String? ?? '';
      final keyPoints =
          (data['keyPoints'] as List?)?.cast<String>() ?? const <String>[];
      final dates =
          (data['dates'] as List?)?.cast<String>() ?? const <String>[];
      return (summary: summary, keyPoints: keyPoints, dates: dates);
    } catch (_) {
      return null;
    }
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

  Future<void> patchExam({
    required String batchId,
    required String id,
    String? kind,
    DateTime? startsAt,
    String? location,
    bool clearLocation = false,
    String? notes,
    bool clearNotes = false,
  }) async {
    await _api.dio.patch('/batches/$batchId/exams/$id', data: {
      if (kind != null) 'kind': kind,
      if (startsAt != null) 'startsAt': startsAt.toUtc().toIso8601String(),
      if (clearLocation) 'location': null,
      if (!clearLocation && location != null) 'location': location,
      if (clearNotes) 'notes': null,
      if (!clearNotes && notes != null) 'notes': notes,
    });
  }

  Future<void> deleteExam({
    required String batchId,
    required String id,
  }) async {
    await _api.dio.delete('/batches/$batchId/exams/$id');
  }
}
