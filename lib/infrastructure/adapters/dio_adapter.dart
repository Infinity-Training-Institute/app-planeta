import 'package:dio/dio.dart';

class DioAdapter {
  final Dio dio;

  DioAdapter()
    : dio = Dio(BaseOptions(validateStatus: (status) => status! < 500)) {
    // Agregar interceptor para logs
    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
      ),
    );
  }

  Future<Response> getRequest(
    String url, {
    Map<String, dynamic>? params,
  }) async {
    try {
      return await dio.get(url, queryParameters: params);
    } catch (e) {
      return Future.error("Error en GET: $e");
    }
  }

  Future<Response> postRequest(String url, String data) async {
    try {
      return await dio.post(
        url,
        data: data, // Mantiene la estructura que ya usas
        options: Options(
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        ),
      );
    } catch (e) {
      return Future.error("Error en POST: $e");
    }
  }
}
