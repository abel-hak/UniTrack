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

  Future<AuthUser> me() async {
    final res = await _api.dio.get<Map<String, dynamic>>('/auth/me');
    final data = res.data!;
    return AuthUser.fromJson(data['user'] as Map<String, dynamic>);
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

