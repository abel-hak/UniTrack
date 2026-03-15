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
    final data = res.data;
    if (data == null) {
      return const TimelineBundle(
        assignments: [],
        announcements: [],
        exams: [],
      );
    }
    final rawAssignments = data['assignments'];
    final rawAnnouncements = data['announcements'];
    final rawExams = data['exams'];
    final assignments = _parseList(rawAssignments, TimelineAssignment.fromJson);
    final announcements = _parseList(rawAnnouncements, TimelineAnnouncement.fromJson);
    final exams = _parseList(rawExams, TimelineExam.fromJson);
    return TimelineBundle(
      assignments: assignments,
      announcements: announcements,
      exams: exams,
    );
  }

  static List<T> _parseList<T>(dynamic raw, T Function(Map<String, dynamic>) fromJson) {
    if (raw is! List) return [];
    final out = <T>[];
    for (final e in raw) {
      if (e is! Map<String, dynamic>) continue;
      try {
        out.add(fromJson(e));
      } catch (_) {
        // skip malformed item
      }
    }
    return out;
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
