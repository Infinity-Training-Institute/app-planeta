import 'package:app_planeta/infrastructure/local_db/app_database.dart';

class RefLibroServices {
  Future<Map<String, dynamic>?> fetchProduct(String refLib) async {
    final db = await AppDatabase.database;

    // Buscar el producto por Referencia o EAN
    final List<Map<String, dynamic>> productMaps = await db.query(
      'Productos',
      where: 'Referencia = ? OR EAN = ?',
      whereArgs: [refLib, refLib],
    );

    if (productMaps.isEmpty) {
      return null;
    }

    final productData = Map<String, dynamic>.from(productMaps[0]);
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
      String tipo = specialProducts['Acumula'] ?? 'N';
      int porcentajeDescuento =
          (specialProducts['Porcentaje_Descuento'] as num?)?.toInt() ?? 0;

      if (porcentajeDescuento != 0) {
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
        productData['Precio'] =
            specialProducts['Precio'] ?? precioProductoNormal;
        productData['Tipo'] = tipo;
      }
    } else {
      productData['Precio'] = precioProductoNormal;
      productData['Tipo'] = 'S';
    }

    final result = {
      'id': productData['id']?.toString() ?? '',
      'ISBN': productData['ISBN']?.toString() ?? '',
      'Descuento_Especial': productData['Descuento_Especial'],
      'EAN': productData['EAN']?.toString() ?? '',
      'Referencia': productData['Referencia']?.toString() ?? '',
      'Desc_Referencia': productData['Desc_Referencia']?.toString() ?? '',
      'Precio': productData['Precio']?.toString() ?? '',
      'Cantidad': productData['Cantidad']?.toString() ?? '',
      'Autor': productData['Autor']?.toString() ?? '',
      'Sello_Editorial': productData['Sello_Editorial']?.toString() ?? '',
      'Familia': productData['Familia']?.toString() ?? '',
      'Tipo': productData['Tipo']?.toString() ?? 'T',
    };

    print(result);

    return result;
  }

  int _calcularDescuento(int base, int descuento) {
    return base - ((base * descuento) ~/ 100);
  }
}
