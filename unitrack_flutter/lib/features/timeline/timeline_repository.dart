import '../../core/api/api_client.dart';
import 'models.dart';

class TimelineRepository {
  final ApiClient _api;
  TimelineRepository(this._api);

  Future<TimelineBundle> fetch({String? courseId}) async {
    final res = await _api.dio.get<Map<String, dynamic>>(
      '/timeline',
      queryParameters: {if (courseId != null) 'courseId': courseId},
    );
    final data = res.data!;
    final assignments = (data['assignments'] as List)
        .cast<Map<String, dynamic>>()
        .map(TimelineAssignment.fromJson)
        .toList();
    final announcements = (data['announcements'] as List)
        .cast<Map<String, dynamic>>()
        .map(TimelineAnnouncement.fromJson)
        .toList();
    final exams = (data['exams'] as List?)
            ?.cast<Map<String, dynamic>>()
            .map(TimelineExam.fromJson)
            .toList() ??
        const [];
    return TimelineBundle(
      assignments: assignments,
      announcements: announcements,
      exams: exams,
    );
  }

  Future<({List<String> items, String note})?> todayPlan() async {
    try {
      final res = await _api.dio.post<Map<String, dynamic>>('/ai/today-plan');
      final data = res.data?['plan'] as Map<String, dynamic>?;
      if (data == null) return null;
      final items =
          (data['items'] as List?)?.map((e) => (e as Map)['title'] as String).toList() ??
              const <String>[];
      final note = data['note'] as String? ?? '';
      return (items: items, note: note);
    } catch (_) {
      return null;
    }
  }
}
