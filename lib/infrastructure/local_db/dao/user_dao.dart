import 'package:sqflite/sqflite.dart';
import '../app_database.dart';
import '../models/user_model.dart';

class UserDao {
  Future<int> insertUser(UserModel user) async {
    final db = await AppDatabase.database;
    return await db.insert('Usuarios', {
      'Cod_Usuario': user.codUsuario,
      'Nombre_Usuario': user.nombreUsuario,
      'Apellido_Usuario': user.apellidoUsuario,
      'Nick_Usuario': user.nickUsuario,
      'Pwd_Usuario': user.pwdUsuario,
      'Tipo_Usuario': user.tipoUsuario,
      'Estado_Usuario': user.estadoUsuario,
      'Serie_Imp_Usuario': user.serieImpUsuario,
      'Factura_Alterna_Usuario': user.facturaAlternaUsuario,
      'Caja_Usuario': user.cajaUsuario,
      'Stand': user.stand,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<UserModel?> getUserByNickAndPwd(
    String usuario,
    String password,
  ) async {
    final db = await AppDatabase.database;

    // Agregar "0" al inicio de la contraseña ingresada
    String modifiedPassword = "$password";

    final List<Map<String, dynamic>> maps = await db.query(
      'Usuarios',
      where: 'Nick_Usuario = ? AND Pwd_Usuario = ?',
      whereArgs: [
        usuario,
        modifiedPassword,
      ], // Comparación sin codificación Base64
    );

    if (maps.isNotEmpty) {
      return UserModel.fromMap(maps.first);
    }
    return null;
  }

  Future<List<UserModel>> getUsers() async {
    final db = await AppDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query('usuarios');
    return List.generate(maps.length, (i) => UserModel.fromMap(maps[i]));
  }

  Future<UserModel?> getUserByNickName(String usuario) async {
    final db = await AppDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query(
      "Usuarios",
      where: 'Nick_Usuario = ?',
      whereArgs: [usuario],
    );

    if (maps.isNotEmpty) {
      return UserModel.fromMap(maps.first);
    }

    return null;
  }

  // metodo para revisar si el usuario existe
  Future<bool> userExists(String usuario) async {
    final db = await AppDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Usuarios',
      where: 'Nick_Usuario = ?',
      whereArgs: [usuario],
    );

    return maps.isNotEmpty;
  }

  Future<int?> getFacturaAlternaUsuario(String usuario) async {
    final db = await AppDatabase.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'Usuarios',
      columns: ['Factura_Alterna_Usuario'],
      where: 'Nick_Usuario = ?',
      whereArgs: [usuario],
    );

    print('Factura Alterna Usuario: $maps');

    if (maps.isNotEmpty) {
      return maps.first['Factura_Alterna_Usuario'] as int?;
    }

    return null;
  }

  Future<void> updateFacturaAlternaUsuario(
    String usuario,
    int facturaAlternaUsuario,
  ) async {
    final db = await AppDatabase.database;

    print('[LOG] Iniciando actualización para el usuario: $usuario');
    print(
      '[LOG] Nuevo valor de Factura_Alterna_Usuario: $facturaAlternaUsuario',
    );

    final count = await db.update(
      'Usuarios',
      {'Factura_Alterna_Usuario': facturaAlternaUsuario},
      where: 'Nick_Usuario = ?',
      whereArgs: [usuario],
    );

    if (count > 0) {
      print('[LOG] Actualización exitosa. Filas modificadas: $count');
    } else {
      print(
        '[LOG] No se modificó ninguna fila. ¿Existe el usuario "$usuario"?',
      );
    }
  }
}
