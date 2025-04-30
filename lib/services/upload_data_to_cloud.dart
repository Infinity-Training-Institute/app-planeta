import 'package:dio/dio.dart';

class UploadDataToCloud {
  final Dio dio = Dio();
  final String apiUrl =
      'https://prologics.co/app_planeta_pruebas/controlador/subir_datos_nube_app.php';

  Future<void> uploadAllData({
    required List<Map<String, dynamic>> mcabfa,
    required List<Map<String, dynamic>> mlinfa,
    required List<Map<String, dynamic>> mclient,
  }) async {
    final payload = {"mcabfa": mcabfa, "mlinfa": mlinfa, "mclient": mclient};

    print(payload);

    try {} catch (e) {
      print('Error al enviar datos: $e');
    }

    try {
      final response = await dio.post(
        apiUrl,
        options: Options(headers: {'Content-Type': 'application/json'}),
        data: payload,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        print('MCABFA insertados: ${data['mcabfa_insertados']}');
        print('MLINFA insertados: ${data['mlinfa_insertados']}');
        print('MCLIENTE insertados: ${data['mcliente_insertados']}');
        print('Errores: ${data['errores']}');
      } else {
        print('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al enviar datos: $e');
    }
  }
}
