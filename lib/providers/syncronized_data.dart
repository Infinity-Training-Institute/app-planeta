import 'package:app_planeta/infrastructure/adapters/dio_adapter.dart';
import 'package:app_planeta/infrastructure/local_db/dao/products_dao.dart';
import 'package:app_planeta/infrastructure/local_db/models/products_model.dart';
import 'package:app_planeta/infrastructure/local_db/dao/update_dao.dart';
import 'package:app_planeta/infrastructure/local_db/models/update_model.dart';
import 'package:flutter/material.dart';
import '../providers/connectivity_provider.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class SyncronizedData with ChangeNotifier {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  bool _isLoading = false;
  String _message = "";

  final dioAdapter = DioAdapter();
  final ProductsDao _productsDao = ProductsDao();
  final ProductsDaoEspecials _productsEspecialsDao = ProductsDaoEspecials();
  final ProductsPaquetesDao _productsPaquetesDao = ProductsPaquetesDao();
  final UpdateDao _updateDao = UpdateDao();

  bool get isLoading => _isLoading;
  String get message => _message;

  Future<void> insertData<T>(
    List<dynamic> dataList,
    Future<void> Function(T) insertFunction,
    T Function(Map<String, dynamic>) modelFromJson,
  ) async {
    for (var item in dataList) {
      try {
        final model = modelFromJson(item);
        print("insertando $model");
        await insertFunction(model);
      } catch (e) {
        print("Error insertando datos: \$e");
      }
    }
  }

  Future<void> getDataToCloud(BuildContext context) async {
    _setLoading(true);
    _message = "";

    // Obtener fecha actual en formato YYYY-MM-DD
    String fechaHoy = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Verificar si ya hay una actualización con la fecha de hoy
    UpdateModel? existingUpdate = await _updateDao.getInfoByDate(fechaHoy);

    if (existingUpdate != null) {
      _message = "Los datos ya están sincronizados hoy.";
      _setLoading(false);
      return;
    }

    // Verificar conexión a internet
    final connectivityProvider = Provider.of<ConnectivityProvider>(
      context,
      listen: false,
    );

    if (!connectivityProvider.isConnected) {
      _setLoading(false);
      return;
    }

    // URLs de descarga
    const String url =
        'https://prologics.co/app_planeta_pruebas/controlador/descarga_productos_nube.php';

    const String urlProductosEspeciales =
        'https://prologics.co/app_planeta_pruebas/controlador/descarga_productos_especiales_nube.php';

    const String urlProductosPaquetes =
        'https://prologics.co/app_planeta_pruebas/controlador/descarga_productos_paquetes_nube.php';

    try {
      final responseProductos = await dioAdapter.getRequest(url);
      final responseEspecial = await dioAdapter.getRequest(
        urlProductosEspeciales,
      );
      final responsePaquete = await dioAdapter.getRequest(urlProductosPaquetes);

      if (responseProductos.statusCode == 200 &&
          responseEspecial.statusCode == 200 &&
          responsePaquete.statusCode == 200) {
        Map<String, dynamic> dataProductos =
            responseProductos.data is String
                ? jsonDecode(responseProductos.data)
                : responseProductos.data;

        Map<String, dynamic> dataEspecial =
            responseEspecial.data is String
                ? jsonDecode(responseEspecial.data)
                : responseEspecial.data;

        Map<String, dynamic> dataPaquetes =
            responsePaquete.data is String
                ? jsonDecode(responsePaquete.data)
                : responsePaquete.data;

        List<dynamic> productosList = dataProductos['productos'];
        List<dynamic> especialList = dataEspecial["productos_especiales"];
        List<dynamic> paqueteList = dataPaquetes["paquetes"];

        await Future.wait([
          insertData<ProductsEspecialsModel>(
            especialList,
            _productsEspecialsDao.insertProductsEspecials,
            (item) => ProductsEspecialsModel(
              id: int.parse(item['id']),
              referencia: item['Referencia'],
              descReferencia: item['Desc_Referencia'],
              porcentajeDescuento: int.parse(item['Porcentaje_Descuento']),
              precio: int.parse(item['Precio']),
              acumula: item['Acumula'],
              acumulaObsequio: item['Acumula_Obsequio'],
              usuario: item['Usuario'],
            ),
          ),
          insertData<ProductsModel>(
            productosList,
            _productsDao.insertProduct,
            (item) => ProductsModel(
              id: int.parse(item['id']),
              ISBN: item['ISBN'],
              EAN: item['EAN'],
              referencia: item['Referencia'],
              descReferencia: item['Desc_Referencia'],
              precio: int.parse(item['Precio']),
              cantidad: int.parse(item['Cantidad']),
              autor: item['Autor'],
              selloEditorial: item['Sello_Editorial'],
              familia: int.parse(item['Familia']),
            ),
          ),
          insertData<ProductsPaquetesModel>(
            paqueteList,
            _productsPaquetesDao.insertProductPaquete,
            (item) => ProductsPaquetesModel(
              id: int.parse(item['id']),
              codigoPaquete: int.parse(item['Codigo_Paquete']),
              codigoEan: item['Codigo_Ean'],
              referencia: item['Referencia'],
              descReferencia: item['Descripcion_Referencia'],
              precio: item['Precio'],
              usuario: item['Usuario'],
            ),
          ),
        ]);

        final update = UpdateModel(fechaActualizacion: fechaHoy);
        await _updateDao.insertUpdate(update);

        _message = "Datos sincronizados correctamente.";
      } else {
        _message = "Error en la descarga de productos.";
      }
    } catch (e) {
      _message = "Error en la conexión con el servidor.";
    }

    _setLoading(false);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
