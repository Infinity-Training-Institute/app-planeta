import 'package:app_planeta/infrastructure/local_db/app_database.dart';
import 'package:app_planeta/infrastructure/local_db/models/datos_cliente_model.dart';

class DatosClienteDao {
  Future<int> insertCliente(DatosClienteModel cliente) async {
    final db = await AppDatabase.database;

    return await db.insert('mclien', {
      "clcecl": cliente.clcecl, // cedula del cliente
      "clnmcl": cliente.clnmcl, // nombre del cliente
      "clpacl": cliente.clpacl, // apellido del cliente
      "clsacl":
          cliente.clsacl.isNotEmpty ? cliente.clsacl : '', // segundo apellido
      "clmail": cliente.clmail, // correo del cliente
      "cldire": cliente.cldire, // direccion del cliente
      "clciud": cliente.clciud, // ciudad del cliente
      "cltele": cliente.cltele, // telefono del cliente
      "clusua": cliente.clusua, // usuario que crea el cliente
      'cl_nube': cliente.cl_nube, // Manejar el campo cl_nube
      "cltipo":
          cliente.cltipo.isNotEmpty ? cliente.cltipo : '', // Manejar vacío
      "clfecha": cliente.clfecha, // fecha de creación del cliente
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
        cl_nube: maps[i]['cl_nube'] ?? '', // Manejar el campo cl_nube
        cltipo: maps[i]['cltipo'],
        clfecha: maps[i]['clfecha'],
      );
    });
  }

  // obtenemos el count de los clientes los cuales en el mnube esten en 0
  Future<int> getCountClientes() async {
    final db = await AppDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'mclien',
      where: 'cl_nube = ?',
      whereArgs: [0],
    );

    return maps.length;
  }

  // actualizamos el mnube a 1 en la base de datos
  Future<int> updateClienteNube(int id) async {
    final db = await AppDatabase.database;
    return await db.update(
      'mclien',
      {'cl_nube': 1},
      where: 'clcecl = ?',
      whereArgs: [id],
    );
  }
}
