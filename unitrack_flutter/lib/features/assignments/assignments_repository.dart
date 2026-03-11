import '../../core/api/api_client.dart';

class AssignmentsRepository {
  final ApiClient _api;
  AssignmentsRepository(this._api);

  Future<void> create({
    required String courseId,
    required String title,
    required String type,
    int? weight,
    required DateTime dueAt,
  }) async {
    await _api.dio.post(
      '/assignments',
      data: {
        'courseId': courseId,
        'title': title,
        'type': type,
        if (weight != null) 'weight': weight,
        'dueAt': dueAt.toUtc().toIso8601String(),
      },
    );
  }

  Future<void> patch({
    required String id,
    String? title,
    String? status,
    int? gradePct,
    bool clearGrade = false,
    int? weight,
    DateTime? dueAt,
  }) async {
    await _api.dio.patch('/assignments/$id', data: {
      if (title != null) 'title': title,
      if (status != null) 'status': status,
      if (clearGrade) 'gradePct': null,
      if (gradePct != null) 'gradePct': gradePct,
      if (weight != null) 'weight': weight,
      if (dueAt != null) 'dueAt': dueAt.toUtc().toIso8601String(),
    });
  }

  Future<void> delete({required String id}) async {
    await _api.dio.delete('/assignments/$id');
  }
}
