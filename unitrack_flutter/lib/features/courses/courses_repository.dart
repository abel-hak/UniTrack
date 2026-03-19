import '../../core/api/api_client.dart';
import 'models.dart';

class CoursesRepository {
  final ApiClient _api;
  CoursesRepository(this._api);

  Future<List<Course>> listCourses({String? batchId}) async {
    final res = await _api.dio.get<Map<String, dynamic>>(
      '/courses',
      queryParameters: {if (batchId != null) 'batchId': batchId},
    );
    final items = (res.data!['courses'] as List).cast<Map<String, dynamic>>();
    return items.map(Course.fromJson).toList();
  }

  Future<Course> create({
    required String batchId,
    required String code,
    required String title,
    required int credits,
    required String colorKey,
    String? instructor,
  }) async {
    final res = await _api.dio.post<Map<String, dynamic>>(
      '/courses',
      data: {
        'batchId': batchId,
        'code': code,
        'title': title,
        'credits': credits,
        'colorKey': colorKey,
        if (instructor != null) 'instructor': instructor,
      },
    );
    return Course.fromJson(res.data!['course'] as Map<String, dynamic>);
  }

  Future<void> update({
    required String id,
    String? title,
    int? credits,
    String? colorKey,
    String? instructor,
  }) async {
    await _api.dio.patch('/courses/$id', data: {
      if (title != null) 'title': title,
      if (credits != null) 'credits': credits,
      if (colorKey != null) 'colorKey': colorKey,
      if (instructor != null) 'instructor': instructor,
    });
  }

  Future<void> delete({required String id}) async {
    await _api.dio.delete('/courses/$id');
  }
}
