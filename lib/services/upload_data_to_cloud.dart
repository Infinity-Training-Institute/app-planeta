import 'package:dio/dio.dart';

class UploadDataToCloud {
  final Dio dio = Dio();
  final String apiUrl =
      'https://prologics.co/app_planeta_pruebas/controlador/subir_datos_nube_app.php';

  Future<void> uploadAllData({
    required List<Map<String, dynamic>> mcabfa,
    required List<Map<String, dynamic>> mlinfa,
    required List<Map<String, dynamic>> mclient,
    required List<Map<String, dynamic>> products,
  }) async {
    final payload = {
      "mcabfa": mcabfa,
      "mlinfa": mlinfa,
      "mclient": mclient,
      "products": products,
    };

    print('Payload: $payload');

    try {
      final response = await dio.post(
        apiUrl,
        data: payload,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      print('Respuesta del servidor: ${response.data}');
    } on DioException catch (e) {
      if (e.response != null) {
        // Verifica si el código de estado es 500 (error del servidor)
        if (e.response?.statusCode == 500) {
          print('Error 500 del servidor: ${e.response?.data}');
        } else {
          print('Error de la respuesta: ${e.response?.statusCode}, ${e.response?.data}');
        }
      } else {
        // Error relacionado con la conexión (sin respuesta)
        print('Error sin respuesta: ${e.message}');
      }
    } catch (e) {
      print('Otro error inesperado: $e');
    }
  }
}
