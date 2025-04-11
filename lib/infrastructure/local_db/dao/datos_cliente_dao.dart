import 'package:app_planeta/infrastructure/local_db/app_database.dart';
import 'package:app_planeta/infrastructure/local_db/models/datos_cliente_model.dart';

class DatosClienteDao {
  Future<int> insertCliente(DatosClienteModel cliente) async {
    final db = await AppDatabase.database;

    return await db.insert('mclien', {
      "clcecl": cliente.clcecl,
      "clnmcl": cliente.clnmcl,
      "clpacl": cliente.clpacl,
      "clsacl": cliente.clsacl.isNotEmpty ? cliente.clsacl : '',
      "clmail": cliente.clmail,
      "cldire": cliente.cldire,
      "clciud": cliente.clciud,
      "cltele": cliente.cltele,
      "clusua": cliente.clusua,
      "cltipo":
          cliente.cltipo.isNotEmpty ? cliente.cltipo : '', // Manejar vacío
      "clfecha": cliente.clfecha,
    });
  }

  Future<List<DatosClienteModel>> getClientes() async {
    final db = await AppDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query('mclien');

    return List.generate(maps.length, (i) {
      return DatosClienteModel(
        clcecl: maps[i]['clcecl'].toString(),
        clnmcl: maps[i]['clnmcl'],
        clpacl: maps[i]['clpacl'],
        clsacl: maps[i]['clsacl'],
        clmail: maps[i]['clmail'],
        cldire: maps[i]['cldire'],
        clciud: maps[i]['clciud'],
        cltele: maps[i]['cltele'],
        clusua: maps[i]['clusua'],
        cltipo: maps[i]['cltipo'],
        clfecha: maps[i]['clfecha'],
      );
    });
  }
}
