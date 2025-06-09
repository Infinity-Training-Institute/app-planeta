import 'package:app_planeta/infrastructure/adapters/dio_adapter.dart';
import 'package:app_planeta/providers/user_provider.dart';
import 'package:app_planeta/services/shared_preferences.dart';
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
  final PromocionesDao _promocionesDao = PromocionesDao();
  final PromocionHoraDao _promocionHoraDao = PromocionHoraDao();
  final PromocionCantidadDao _promocionCantidadDao = PromocionCantidadDao();
  final SharedPreferencesService _prefsService = SharedPreferencesService();
  var opcionesDescarga = {};

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
    await _prefsService.init();
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

    // consultamos el stand
    final userProvider = Provider.of<StandProvider>(context, listen: false);
  

    // url de descarga
    final String url =
    'https://prologics.co/app_planeta_pruebas/controlador/descarga_datos_nube.php?stand=${userProvider.stand}';

    try {
      final responseData = await dioAdapter.getRequest(url);

      if (responseData.statusCode == 200) {
        Map<String, dynamic> data =
            responseData.data is String
                ? jsonDecode(responseData.data)
                : responseData.data;

        final keys = [
          'productos',
          'productosEspeciales',
          'productosPaquetes',
          'textoFactura',
          'datosCaja',
          'datosEmpresa',
          'promociones',
          'promocionHora',
          'promocionCantidad',
        ];

        opcionesDescarga = _prefsService.getMultipleBools(keys);

        // Imprime todas las claves y valores
        opcionesDescarga.forEach((key, value) {
          print('Pref $key = $value');
        });

        // Verificar si todas las preferencias están en false
        bool todasPreferenciasFalse = true;
        opcionesDescarga.forEach((key, value) {
          if (value == true) {
            todasPreferenciasFalse = false;
          }
        });

        if (todasPreferenciasFalse) {
          _message = "Ninguna preferencia seleccionada.";
          return; // Salir de la función temprano
        }

        List<dynamic> productList = data['productos'];
        List<dynamic> especiaList = data['productos_especiales'];
        List<dynamic> paqueteList = data['paquetes'];
        List<dynamic> textoFacturaList = data['texto_factura'];
        List<dynamic> datosCajaList = data['datos_caja'];
        List<dynamic> datosEmpresaList = data['datos_empresa'];
        List<dynamic> datosPromocionList = data['datos_promociones'];
        List<dynamic> datosPromocionHorasList = data['datos_promocion_horas'];
        List<dynamic> datosPromocionCantidadList =
            data['datos_promocion_cantidad'];

        // Creamos un mapa para llevar registro de los contadores
        Map<String, int> insertCounters = {};

        await Future.wait([
          // Manejamos promociones - solo si está activado
          if (opcionesDescarga['promociones'] == true)
            () async {
              // verificamos si la lista de promociones esta vacia
              await clearIfEmpty(
                serverList: datosPromocionList,
                localCount: _promocionesDao.countPromociones,
                deleteAll: _promocionesDao.deleteAll,
              );

              await _promocionesDao.deleteAll();

              // insertamos si esta activa
              await insertData<PromocionesModel>(
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
              );

              // Almacenamos el conteo después de insertar
              int countPromociones = datosPromocionList.length;
              insertCounters['promociones'] = countPromociones;
              return;
            }(),

          if (opcionesDescarga['promocionHora'] == true)
            () async {
              await clearIfEmpty(
                serverList: datosPromocionHorasList,
                localCount: _promocionHoraDao.countPromocionHoras,
                deleteAll: _promocionHoraDao.deleteAll,
              );

              await _promocionHoraDao.deleteAll();

              await insertData<PromocionHorasModel>(
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
              );

              int countPromocionHoras = datosPromocionHorasList.length;
              insertCounters['promocionHora'] = countPromocionHoras;
              return;
            }(),

          if (opcionesDescarga['promocionCantidad'] == true)
            () async {
              await clearIfEmpty(
                serverList: datosPromocionCantidadList,
                localCount: _promocionCantidadDao.countPromocionCantidad,
                deleteAll: _promocionCantidadDao.deleteAll,
              );

              await _promocionCantidadDao.deleteAll();

              await insertData<PromocionCantidadModel>(
                datosPromocionCantidadList,
                _promocionCantidadDao.insertPromocionCantidad,
                (item) => PromocionCantidadModel(
                  codPromocion: int.tryParse(item['Cod_Promocion'].toString()),
                  productosDesde: int.tryParse(
                    item['Productos_Desde'].toString(),
                  ),
                  productosHasta: int.tryParse(
                    item['Productos_Hasta'].toString(),
                  ),
                  porcentajeDescuento:
                      int.tryParse(
                        item['Porcentaje_Descuento'].toString(),
                      )?.toString(),
                  obsequio: item['Obsequio'],
                  usuario: item['Usuario'],
                ),
              );

              int countPromocionCantidad = datosPromocionCantidadList.length;
              insertCounters['promocionCantidad'] = countPromocionCantidad;
              return;
            }(),

          if (opcionesDescarga['textoFactura'] == true)
            () async {
              await insertData<TextFacturaModel>(
                textoFacturaList,
                _textFacturaDao.insertText,
                (item) => TextFacturaModel(
                  id: int.parse(item['id']),
                  descripcion: item['descripcion'],
                ),
              );

              int countTextoFactura = textoFacturaList.length;
              insertCounters['textoFactura'] = countTextoFactura;
              return;
            }(),

          if (opcionesDescarga['datosCaja'] == true)
            () async {
              await insertData<DatosCajaModel>(
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
                  facturaFinal: item['Factura_Final'],
                  datosNube: 0
                ),
              );

              int countDatosCaja = datosCajaList.length;
              insertCounters['datosCaja'] = countDatosCaja;
              return;
            }(),

          if (opcionesDescarga['datosEmpresa'] == true)
            () async {
              await insertData<DatosEmpresaModel>(
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
              );

              int countDatosEmpresa = datosEmpresaList.length;
              insertCounters['datosEmpresa'] = countDatosEmpresa;
              return;
            }(),

          if (opcionesDescarga['productos'] == true)
            () async {
              await insertData<ProductsModel>(
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
                  mnube: 1,
                ),
              );

              int countProductos = productList.length;
              insertCounters['productos'] = countProductos;
              return;
            }(),

          if (opcionesDescarga['productosEspeciales'] == true)
            () async {
              await insertData<ProductsEspecialsModel>(
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
              );

              int countProductosEspeciales = especiaList.length;
              insertCounters['productosEspeciales'] = countProductosEspeciales;
              return;
            }(),

          if (opcionesDescarga['productosPaquetes'] == true)
            () async {
              await insertData<ProductsPaquetesModel>(
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
              );

              int countProductosPaquetes = paqueteList.length;
              insertCounters['productosPaquetes'] = countProductosPaquetes;
              return;
            }(),
        ]);

        final update = UpdateModel(fechaActualizacion: fechaHoy);
        await _updateDao.insertUpdate(update);

        // Construir el mensaje final con los contadores
        StringBuffer messageBuffer = StringBuffer(
          "Datos sincronizados correctamente:\n",
        );
        insertCounters.forEach((key, value) {
          messageBuffer.write("- $key: $value registros insertados\n");
        });

        _message = messageBuffer.toString();
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
