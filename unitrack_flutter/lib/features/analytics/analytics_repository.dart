import '../../core/api/api_client.dart';
import 'models.dart';

class AnalyticsRepository {
  final ApiClient _api;
  AnalyticsRepository(this._api);

  Future<AnalyticsOverview> overview() async {
    final res = await _api.dio.get<Map<String, dynamic>>('/analytics/overview');
    return AnalyticsOverview.fromJson(res.data!);
  }

  Future<List<TrendPoint>> trend() async {
    final res = await _api.dio.get<Map<String, dynamic>>('/analytics/trend');
    final points = (res.data!['points'] as List).cast<Map<String, dynamic>>();
    return points.map(TrendPoint.fromJson).toList();
  }

  Future<TargetResult> target({
    required String courseId,
    required double targetPct,
  }) async {
    final res = await _api.dio.post<Map<String, dynamic>>(
      '/analytics/target',
      data: {'courseId': courseId, 'targetPct': targetPct},
    );
    return TargetResult.fromJson(res.data!);
  }

  Future<GpaProjection> projection() async {
    final res =
        await _api.dio.get<Map<String, dynamic>>('/analytics/projection');
    return GpaProjection.fromJson(res.data!);
  }
}
