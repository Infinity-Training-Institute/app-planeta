import 'package:app_planeta/infrastructure/adapters/dio_adapter.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../infrastructure/local_db/models/user_model.dart';
import '../infrastructure/local_db/dao/user_dao.dart';
import '../providers/connectivity_provider.dart';
import 'package:provider/provider.dart';
import 'dart:developer';
import 'dart:convert';

class AuthProvider with ChangeNotifier {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  bool _isAuthenticated = false;
  bool _userIsNotFound = false;
  bool _credentialsAreInvalid = false;
  bool _isLoading = false;
  String _message = "";

  bool get isAuthenticated => _isAuthenticated;
  bool get notFound => _userIsNotFound;
  bool get invalidCredentials => _credentialsAreInvalid;
  bool get isLoading => _isLoading;
  String get message => _message;

  final dioAdapter = DioAdapter();

  Future<void> login(
    String email,
    String password,
    BuildContext context,
  ) async {
    _setLoading(true);
    _message = ""; // Reinicia el mensaje antes de la petición

    // verificamos la conexión a internet
    final connectivityProvider = Provider.of<ConnectivityProvider>(
      context,
      listen: false,
    );

    // si no hay internet usamos la base de datos local
    if (!connectivityProvider.isConnected) {
      print(email);
      print(password);
      final localUser = await UserDao().getUserByNickAndPwd(email, password);
      print(localUser);

      if (localUser != null) {
        _isAuthenticated = true;
        _message = "Inicio de sesión sin conexión exitoso";
      } else {
        _isAuthenticated = false;
        _userIsNotFound = true;
        _message = "Usuario no encontrado en la base de datos local";
      }
      _setLoading(false);
      return;
    }

    //si hay conexión a internet
    const String url =
        'https://prologics.co/app_planeta_pruebas/controlador/login_app.php';
    final String postData = "usuario=$email&password=$password";

    try {
      final response = await dioAdapter.postRequest(url, postData);
      _updateState(response);

      if (_isAuthenticated) {
        dynamic responseUser;
        if (response.data is String) {
          responseUser = jsonDecode(response.data);
        } else {
          responseUser = response.data;
        }

        // Guardar el usuario en la base de datos local
        final userData =
            responseUser['usuario'][0]; // Ahora sí accedemos a usuario

        String decodedPwd = utf8.decode(base64.decode(userData['Pwd_Usuario']));

        // Crear instancia de UserModel con los datos extraídos
        final nuevoUsuario = UserModel(
          codUsuario: int.parse(userData['Cod_Usuario']), // Convertir a int
          nombreUsuario: userData['Nombre_Usuario'],
          apellidoUsuario: userData['Apellido_Usuario'],
          nickUsuario: userData['Nick_Usuario'],
          pwdUsuario: decodedPwd,
          tipoUsuario: int.parse(userData['Tipo_Usuario']),
          estadoUsuario: int.parse(userData['Estado_Usuario']),
          serieImpUsuario: userData['Serie_Imp_Usuario'] ?? '',
          facturaAlternaUsuario: int.parse(userData['Factura_Alterna_Usuario']),
          cajaUsuario: userData['Caja_Usuario'],
          stand: userData['Stand'],
        );

        // Guardar el usuario en la base de datos local
        final userDao = UserDao();
        await userDao.insertUser(nuevoUsuario);
      }
    } catch (e) {
      _isAuthenticated = false;
      _userIsNotFound = false;
      _credentialsAreInvalid = false;
      _message = "Error en la conexión con el servidor";
      log('Error en la petición: $e');
    }

    _setLoading(false);
  }

  void _updateState(Response response) {
    dynamic mensaje;

    if (response.data is String) {
      mensaje = jsonDecode(response.data);
    } else {
      mensaje = response.data;
    }
    _message =
        mensaje['message'] ??
        "Error desconocido"; // Extrae el mensaje de la API

    _isAuthenticated = response.statusCode == 200;
    _userIsNotFound = response.statusCode == 404;
    _credentialsAreInvalid = !(_isAuthenticated || _userIsNotFound);
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void logout() {
    _isAuthenticated = false;
    notifyListeners();
  }
}
