import 'package:dio/dio.dart';

import '../api/api_client.dart';
import 'models.dart';

class AuthRepository {
  final ApiClient _api;

  AuthRepository(this._api);

  Future<(String token, AuthUser user)> login({
    required String email,
    required String password,
  }) async {
    final res = await _api.dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    final data = res.data!;
    return (
      data['token'] as String,
      AuthUser.fromJson(data['user'] as Map<String, dynamic>)
    );
  }

  Future<(String token, AuthUser user)> register({
    required String name,
    required String email,
    required String password,
    required String batchId,
  }) async {
    final res = await _api.dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'name': name,
        'email': email,
        'password': password,
        'batchId': batchId,
      },
    );
    final data = res.data!;
    return (
      data['token'] as String,
      AuthUser.fromJson(data['user'] as Map<String, dynamic>)
    );
  }

  Future<AuthUser> me() async {
    final res = await _api.dio.get<Map<String, dynamic>>('/auth/me');
    final data = res.data!;
    return AuthUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _api.dio.patch('/auth/password', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  Future<List<Batch>> listBatches() async {
    final res = await _api.dio.get<Map<String, dynamic>>('/batches');
    final items =
        (res.data!['batches'] as List).cast<Map<String, dynamic>>();
    return items.map(Batch.fromJson).toList();
  }

  Future<bool> health() async {
    try {
      await _api.dio.get('/health');
      return true;
    } on DioException {
      return false;
    }
  }
}
