import 'package:sqflite/sqflite.dart';
import '../app_database.dart';
import '../models/user_model.dart';
import 'dart:convert';

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

    // Codificar la contraseña ingresada en Base64 para compararla
    String encodedPassword = base64.encode(utf8.encode(password));

    final List<Map<String, dynamic>> maps = await db.query(
      'Usuarios',
      where: 'Nick_Usuario = ? AND Pwd_Usuario = ?',
      whereArgs: [
        usuario,
        encodedPassword,
      ], // Comparación con la contraseña codificada
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

  Future<int> updateUser(UserModel user) async {
    final db = await AppDatabase.database;
    return await db.update(
      'usuarios',
      user.toMap(),
      where: 'Cod_Usuario = ?',
      whereArgs: [user.codUsuario],
    );
  }

  Future<int> deleteUser(int id) async {
    final db = await AppDatabase.database;
    return await db.delete(
      'usuarios',
      where: 'Cod_Usuario = ?',
      whereArgs: [id],
    );
  }
}
