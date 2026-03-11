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
}

