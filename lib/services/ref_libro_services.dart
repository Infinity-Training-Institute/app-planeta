import 'package:app_planeta/infrastructure/local_db/app_database.dart';

class RefLibroServices {
  Future<Map<String, dynamic>> fetchProduct(String refLib) async {
    final db = await AppDatabase.database;

    Map<String, dynamic> data = {};

    // Buscar el producto por Referencia o EAN
    final List<Map<String, dynamic>> productMaps = await db.query(
      'Productos',
      where: 'Referencia = ? OR EAN = ?',
      whereArgs: [refLib, refLib],
    );

    if (productMaps.isNotEmpty) {
      final productData = productMaps[0];
      int precioProductoNormal = (productData['Precio'] as num).toInt();
      String referenciaEAN = productData['Referencia'].toString().trim();

      // Buscar si el producto tiene descuentos en la tabla Productos_Especiales
      final List<Map<String, dynamic>> specialProductMaps = await db.query(
        'Productos_Especiales',
        where: 'Referencia = ? OR Referencia = ?',
        whereArgs: [refLib, referenciaEAN],
      );

      if (specialProductMaps.isNotEmpty) {
        final specialProducts = specialProductMaps[0];
        String tipo = specialProducts['Acumula'];
        data['Tipo'] = tipo;
        data['Precio'] = specialProducts['Precio'];
        int porcentajeDescuento =
            (specialProducts['Porcentaje_Descuento'] as num).toInt();

        if (porcentajeDescuento != 0) {
          // Si el tipo es 'N', no aplico ninguna promoción diferente
          if (tipo == 'N') {
            productData['Precio'] = precioProductoNormal;
            productData['Tipo'] = 'N';
            productData['Descuento_Especial'] = porcentajeDescuento;
          } else {
            productData['Precio'] = _calcularDescuento(
              precioProductoNormal,
              porcentajeDescuento,
            );
            productData['Tipo'] = 'S';
          }
        } else {
          // Si no hay descuento, se asigna el precio especial
          data['Precio'] = specialProducts['Precio'];
        }
      } else {
        // Si no hay productos especiales, asigno un tipo 'S' por defecto
        data['Tipo'] = 'S';
        data['Precio'] = precioProductoNormal;
      }

      // Convertir los datos en el formato esperado
      Map<String, dynamic> formattedData = {
        '0': productData['id'],
        '1': productData['ISBN'].toString(),
        '2': productData['EAN'].toString(),
        '3': productData['Referencia'].toString(),
        '4': productData['Desc_Referencia'].toString(),
        '5': productData['Precio'].toString(),
        '6': productData['Cantidad'].toString(),
        '7': productData['Autor'].toString(),
        '8': productData['Sello_Editorial'].toString(),
        '9': productData['Familia'].toString(),
        'id': productData['id'].toString(),
        'ISBN': productData['ISBN'].toString(),
        'EAN': productData['EAN'].toString(),
        'Referencia': productData['Referencia'].toString(),
        'Desc_Referencia': productData['Desc_Referencia'].toString(),
        'Precio': productData['Precio'].toString(),
        'Cantidad': productData['Cantidad'].toString(),
        'Autor': productData['Autor'].toString(),
        'Sello_Editorial': productData['Sello_Editorial'].toString(),
        'Familia': productData['Familia'].toString(),
        'Tipo': data['Tipo'].toString(),
      };

      return formattedData;
    } else {
      return {};
    }
  }

  int _calcularDescuento(int base, int descuento) {
    return base - ((base * descuento) ~/ 100);
  }
}
