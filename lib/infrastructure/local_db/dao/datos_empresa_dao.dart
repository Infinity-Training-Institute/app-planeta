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

  Future<List<DatosEmpresaModel>> getEmpresas() async {
    final db = await AppDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query('Datos_Empresa');

    return List.generate(maps.length, (i) {
      return DatosEmpresaModel(
        id:
            maps[i]['Id'] is int
                ? maps[i]['Id']
                : int.tryParse(maps[i]['Id'].toString()),
        nombreEmpresa: maps[i]['Nombre_Empresa'],
        nit: maps[i]['Nit'],
        direccion: maps[i]['Direccion'],
        telefono: maps[i]['Telefono'],
        email: maps[i]['Email'],
        logo:
            maps[i]['Logo'] is int
                ? maps[i]['Logo']
                : int.tryParse(maps[i]['Logo'].toString()) ?? 0,
      );
    });
  }
}
