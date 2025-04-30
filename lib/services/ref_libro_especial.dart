import 'package:app_planeta/infrastructure/local_db/app_database.dart';

class RefLibroEspecial {
  Future<String> getTipoLibro(String refLib) async {
    final db = await AppDatabase.database;

    final List<Map<String, dynamic>> result = await db.query(
      'Productos_Especiales',
      where: 'Referencia = ?',
      whereArgs: [refLib],
    );

    if (result.isNotEmpty) {
      return result.first['Acumula'] ?? 'S';
    } else {
      return 'S';
    }
  }

  Future<Map<String, dynamic>?> fetchProduct(String refLib) async {
    final db = await AppDatabase.database;

    final List<Map<String, dynamic>> productMaps = await db.query(
      'Productos',
      where: 'Referencia = ? OR EAN = ?',
      whereArgs: [refLib, refLib],
    );

    if (productMaps.isEmpty) return null;

    final productData = Map<String, dynamic>.from(productMaps[0]);
    int precioProductoNormal = (productData['Precio'] as num).toInt();
    String referenciaProducto = productData['Referencia'].toString().trim();

    final List<Map<String, dynamic>> especialesMaps = await db.query(
      'Productos_Especiales',
      where: 'Referencia = ? OR Referencia = ?',
      whereArgs: [refLib, referenciaProducto],
    );

    if (especialesMaps.isNotEmpty) {
      final especiales = especialesMaps[0];
      int porcentajeDescuento =
          (especiales['Porcentaje_Descuento'] as num?)?.toInt() ?? 0;
      String acumula = especiales['Acumula']?.toString() ?? 'N';

      if (porcentajeDescuento != 0) {
        if (acumula == 'N') {
          productData['Precio'] = precioProductoNormal;
          productData['Tipo'] = 'N';
        } else {
          productData['Precio'] = precioProductoNormal;
          productData['Tipo'] = 'S';
        }
      } else {
        productData['Precio'] = especiales['Precio'] ?? precioProductoNormal;
        productData['Tipo'] = acumula;
      }
    } else {
      productData['Tipo'] = 'S';
    }

    final result = {
      'id': productData['id']?.toString() ?? '',
      'ISBN': productData['ISBN']?.toString() ?? '',
      'Descuento_Especial':
          especialesMaps.isNotEmpty
              ? especialesMaps[0]['Porcentaje_Descuento']
              : null,
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
}
