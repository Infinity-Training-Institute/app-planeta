import 'package:app_planeta/infrastructure/local_db/app_database.dart';
import 'package:app_planeta/infrastructure/local_db/models/datos_empresa_model.dart';
import 'package:sqflite/sql.dart';

class DatosEmpresaDao {
  Future<int> insertEmpresa(DatosEmpresaModel empresa) async {
    final db = await AppDatabase.database;

    return await db.insert('Datos_Empresa', {
      'Id': empresa.id,
      'Nombre_Empresa': empresa.nombreEmpresa,
      'Nit': empresa.nit,
      'Direccion': empresa.direccion,
      'Telefono': empresa.telefono,
      'Email': empresa.email,
      'Logo': empresa.logo,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
