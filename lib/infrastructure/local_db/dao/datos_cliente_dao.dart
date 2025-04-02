import 'package:app_planeta/infrastructure/local_db/app_database.dart';
import 'package:app_planeta/infrastructure/local_db/models/datos_cliente_model.dart';

class DatosClienteDao {
  Future<int> insertCliente(DatosClienteModel cliente) async {
    final db = await AppDatabase.database;

    return await db.insert('mclien', {
      "clcecl": cliente.clcecl,
      "clnmcl": cliente.clnmcl,
      "clpacl": cliente.clpacl,
      "clsacl": cliente.clsacl,
      "clmail": cliente.clmail,
      "cldire": cliente.cldire,
      "clciud": cliente.clciud,
      "cltele": cliente.cltele,
      "clusua": cliente.clusua,
      "cltipo": cliente.cltipo,
      "clfecha": cliente.clfecha,
    });
  }
}
