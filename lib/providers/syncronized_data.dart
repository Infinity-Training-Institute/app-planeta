import 'package:app_planeta/infrastructure/adapters/dio_adapter.dart';
import 'package:flutter/material.dart';
import '../providers/connectivity_provider.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

// importacion modelos y dao
import '../infrastructure/local_db/models/index.dart';
import '../infrastructure/local_db/dao/index.dart';

class SyncronizedData with ChangeNotifier {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  bool _isLoading = false;
  String _message = "";

  final dioAdapter = DioAdapter();
  final UpdateDao _updateDao = UpdateDao();
  final ProductsDao _productsDao = ProductsDao();
  final ProductsDaoEspecials _productsEspecialsDao = ProductsDaoEspecials();
  final ProductsPaquetesDao _productsPaquetesDao = ProductsPaquetesDao();
  final TextFacturaDao _textFacturaDao = TextFacturaDao();
  final DatosCajaDao _cajaDao = DatosCajaDao();
  final DatosEmpresaDao _datosEmpresaDao = DatosEmpresaDao();
  final DatosClienteDao _datosClienteDao = DatosClienteDao();
  final PromocionesDao _promocionesDao = PromocionesDao();
  final PromocionHoraDao _promocionHoraDao = PromocionHoraDao();
  final PromocionCantidadDao _promocionCantidadDao = PromocionCantidadDao();

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
        await insertFunction(model);
      } catch (e) {
        print("Error insertando datos: $e");
      }
    }
  }

  Future<void> clearIfEmpty<T>({
    required List<dynamic>? serverList,
    required Future<int> Function() localCount,
    required Future<void> Function() deleteAll,
  }) async {
    if ((serverList == null || serverList.isEmpty) && await localCount() > 0) {
      await deleteAll();
    }
  }

  Future<void> getDataToCloud(BuildContext context) async {
    _setLoading(true);
    _message = "";

    // Obtener fecha actual en formato YYYY-MM-DD
    String fechaHoy = DateFormat('yyyy-MM-dd').format(DateTime.now());

    if (!context.mounted) return;

    // Verificar conexión a internet
    final connectivityProvider = Provider.of<ConnectivityProvider>(
      context,
      listen: false,
    );

    if (!connectivityProvider.isConnected) {
      _setLoading(false);
      return;
    }

    // url de descarga
    const String url =
        'https://prologics.co/app_planeta_pruebas/controlador/descarga_datos_nube.php';

    try {
      final responseData = await dioAdapter.getRequest(url);

      if (responseData.statusCode == 200) {
        Map<String, dynamic> data =
            responseData.data is String
                ? jsonDecode(responseData.data)
                : responseData.data;

        List<dynamic> productList = data['productos'];
        List<dynamic> especiaList = data['productos_especiales'];
        List<dynamic> paqueteList = data['paquetes'];
        List<dynamic> textoFacturaList = data['texto_factura'];
        List<dynamic> datosCajaList = data['datos_caja'];
        List<dynamic> datosEmpresaList = data['datos_empresa'];
        List<dynamic> datosClienteList = data['datos_cliente'];
        List<dynamic> datosPromocionList = data['datos_promociones'];
        List<dynamic> datosPromocionHorasList = data['datos_promocion_horas'];
        List<dynamic> datosPromocionCantidadList =
            data['datos_promocion_cantidad'];

        // verificamos si la lista de promociones esta vacia
        await clearIfEmpty(
          serverList: datosPromocionList,
          localCount: _promocionesDao.countPromociones,
          deleteAll: _promocionesDao.deleteAll,
        );

        await clearIfEmpty(
          serverList: datosPromocionHorasList,
          localCount: _promocionHoraDao.countPromocionHoras,
          deleteAll: _promocionHoraDao.deleteAll,
        );

        await clearIfEmpty(
          serverList: datosPromocionCantidadList,
          localCount: _promocionCantidadDao.countPromocionCantidad,
          deleteAll: _promocionCantidadDao.deleteAll,
        );

        // eliminamos los datos de la tabla de promociones
        await _promocionesDao.deleteAll();
        await _promocionHoraDao.deleteAll();
        await _promocionCantidadDao.deleteAll();

        await Future.wait([
          insertData<PromocionesModel>(
            datosPromocionList,
            _promocionesDao.insertPromocion,
            (item) => PromocionesModel(
              codPromocion: int.tryParse(item['Cod_Promocion'].toString()),
              fechaPromocion: item['Fecha_Promocion'],
              horaDesde: item['Hora_Desde'],
              minutoDesde: item['Minuto_Desde'],
              horaHasta: item['Hora_Hasta'],
              minutoHasta: item['Minuto_Hasta'],
              usuario: item['Usuario'],
              tipoPromocion: item['Tipo_Promocion'],
            ),
          ),
          insertData<PromocionHorasModel>(
            datosPromocionHorasList,
            _promocionHoraDao.inserPromocionHora,
            (item) => PromocionHorasModel(
              codPromocion: int.tryParse(item['Cod_Promocion'].toString()),
              fechaPromocion: item['Fecha_Promocion'],
              horaDesde: item['Hora_Desde'],
              minutoDesde: item['Minuto_Desde'],
              horaHasta: item['Hora_Hasta'],
              minutoHasta: item['Minuto_Hasta'],
              descuentoPromocion:
                  int.tryParse(
                    item['Descuento_Promocion'].toString(),
                  )?.toString(),
              usuario: item['Usuario'],
            ),
          ),
          insertData<PromocionCantidadModel>(
            datosPromocionCantidadList,
            _promocionCantidadDao.insertPromocionCantidad,
            (item) => PromocionCantidadModel(
              codPromocion: int.tryParse(item['Cod_Promocion'].toString()),
              productosDesde: int.tryParse(item['Productos_Desde'].toString()),
              productosHasta: int.tryParse(item['Productos_Hasta'].toString()),
              porcentajeDescuento:
                  int.tryParse(
                    item['Porcentaje_Descuento'].toString(),
                  )?.toString(),
              obsequio: item['Obsequio'],
              usuario: item['Usuario'],
            ),
          ),
          insertData<TextFacturaModel>(
            textoFacturaList,
            _textFacturaDao.insertText,
            (item) => TextFacturaModel(
              id: int.parse(item['id']),
              descripcion: item['descripcion'],
            ),
          ),
          insertData<DatosCajaModel>(
            datosCajaList,
            _cajaDao.insertCaja,
            (item) => DatosCajaModel(
              codCaja:
                  item['Cod_Caja'] != null
                      ? int.tryParse(item['Cod_Caja'].toString())
                      : null,
              stand: item['Stand'],
              numeroCaja: item['Numero_Caja'],
              facturaInicio: item['Factura_Inicio'],
              numeroResolucion: item['Numero_Resolucion'],
              facturaActual: item['Factura_Actual'],
              nickUsuario: item['Nick_Usuario'],
              claveTecnica: item['Clave_Tecnica'],
            ),
          ),
          insertData<DatosEmpresaModel>(
            datosEmpresaList,
            _datosEmpresaDao.insertEmpresa,
            (item) => DatosEmpresaModel(
              id:
                  item['Id'] != null
                      ? int.tryParse(item['Id'].toString())
                      : null,
              nombreEmpresa: item['Nombre_Empresa'],
              nit: item['Nit'],
              direccion: item['Direccion'],
              telefono: item['Telefono'],
              email: item['Email'],
              logo:
                  item['Logo'] != null
                      ? int.tryParse(item['Logo'].toString()) ?? 0
                      : 0,
            ),
          ),
          insertData<DatosClienteModel>(
            datosClienteList,
            _datosClienteDao.insertCliente,
            (item) => DatosClienteModel(
              clcecl: item['clcecl'],
              clnmcl: item['clnmcl'],
              clpacl: item['clpacl'],
              clsacl: item['clsacl'],
              clmail: item['clmail'],
              cldire: item['cldire'],
              clciud: item['clciud'],
              cltele: item['cltele'],
              clusua: item['clusua'],
              cltipo: item['cltipo'],
              clfecha: item['clfecha'],
              cl_nube: 1 as String, // Manejar el campo cl_nube
            ),
          ),
          insertData<ProductsModel>(
            productList,
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
          insertData<ProductsEspecialsModel>(
            especiaList,
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
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
