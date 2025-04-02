import 'package:app_planeta/infrastructure/local_db/app_database.dart';
import 'package:app_planeta/infrastructure/local_db/models/text_factura_model.dart';
import 'package:sqflite/sql.dart';

class TextFacturaDao {
  Future<int> insertText(TextFacturaModel text) async {
    final db = await AppDatabase.database;
    return await db.insert('Texto_Factura', {
      'id': text.id,
      'descripcion': text.descripcion,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<TextFacturaModel>> getTextFactura() async {
    final db = await AppDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query('Texto_Factura');

    if (maps.isNotEmpty) {
      return List.generate(
        maps.length,
        (i) => TextFacturaModel.fromMap(maps[i]),
      );
    }
    return [];
  }
}
