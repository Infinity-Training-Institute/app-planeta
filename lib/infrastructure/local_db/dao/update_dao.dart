import 'package:app_planeta/infrastructure/local_db/models/update_model.dart';
import 'package:sqflite/sqflite.dart';
import '../app_database.dart';

class UpdateDao {
  Future<int> insertUpdate(UpdateModel update) async {
    final db = await AppDatabase.database;

    return await db.insert('actualizacion_datos', {
      'id': update.id,
      'fecha_actualizacion': update.fechaActualizacion,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<UpdateModel?> getInfoByDate(String fecha) async {
    final db = await AppDatabase.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'actualizacion_datos',
      where: 'fecha_actualizacion = ?',
      whereArgs: [fecha],
    );

    if (maps.isNotEmpty) {
      return UpdateModel.fromMap(maps.first);
    }

    return null; // Retorna null si no hay datos
  }
}
