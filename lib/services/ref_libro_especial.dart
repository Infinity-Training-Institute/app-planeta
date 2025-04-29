import 'package:app_planeta/infrastructure/local_db/app_database.dart';

class RefLibroEspecial {
  Future<String> getTipoLibro(String refLib) async {
    final db = await AppDatabase.database;

    final List<Map<String, dynamic>> result = await db.query(
      'Productos_Especiales',
      where: 'Referencia = ?',
      whereArgs: [refLib],
    );

    if (result.isNotEmpty) {
      return result.first['Acumula'] ?? 'S';
    } else {
      return 'S';
    }
  }
}
