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
    return TimelineBundle(assignments: assignments, announcements: announcements);
  }
}

