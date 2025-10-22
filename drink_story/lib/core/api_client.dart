import 'package:dio/dio.dart';
import 'config.dart';

class ApiClient {
  final Dio dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBase,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
  ));

  /// Возвращает:
  /// {license_id, route_id, signature, package_url, checksum_sha256, ...}
  Future<Map<String, dynamic>> activate(String token) async {
    final r = await dio.post('/license/activate', data: {'token': token});
    return (r.data as Map).cast<String, dynamic>();
  }
}
