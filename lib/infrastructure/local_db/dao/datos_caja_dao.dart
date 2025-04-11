import 'package:app_planeta/infrastructure/local_db/app_database.dart';
import 'package:app_planeta/infrastructure/local_db/models/datos_caja_model.dart';
import 'package:sqflite/sql.dart';

class DatosCajaDao {
  Future<int> insertCaja(DatosCajaModel caja) async {
    final db = await AppDatabase.database;

    return await db.insert('Datos_Caja', {
      'Cod_Caja': caja.codCaja,
      'Stand': caja.stand,
      'Numero_Caja': caja.numeroCaja,
      'Factura_Inicio': caja.facturaInicio,
      'Numero_Resolucion': caja.numeroResolucion,
      'Factura_Actual': caja.facturaActual,
      'Nick_Usuario': caja.nickUsuario,
      'Clave_Tecnica': caja.claveTecnica,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<DatosCajaModel>> getCajas() async {
    final db = await AppDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query('Datos_Caja');

    return List.generate(maps.length, (i) {
      return DatosCajaModel(
        codCaja: maps[i]['Cod_Caja'],
        stand: maps[i]['Stand'],
        numeroCaja: maps[i]['Numero_Caja'],
        facturaInicio: maps[i]['Factura_Inicio'].toString(),
        numeroResolucion: maps[i]['Numero_Resolucion'],
        facturaActual: maps[i]['Factura_Actual'].toString(),
        nickUsuario: maps[i]['Nick_Usuario'],
        claveTecnica: maps[i]['Clave_Tecnica'],
      );
    });
  }
}
