import 'package:app_planeta/infrastructure/local_db/app_database.dart';
import 'package:app_planeta/infrastructure/local_db/models/products_model.dart';
import 'package:sqflite/sql.dart';

class ProductsDao {
  Future<int> insertProduct(ProductsModel product) async {
    final db = await AppDatabase.database;
    return await db.insert('Productos', {
      'ISBN': product.ISBN,
      'EAN': product.EAN,
      'Referencia': product.referencia,
      'Desc_Referencia': product.descReferencia,
      'Precio': product.precio,
      'Cantidad': product.cantidad,
      'Autor': product.autor,
      'Sello_Editorial': product.selloEditorial,
      'Familia': product.familia,
      'mnube': product.mnube,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ProductsModel>> getAllProducts() async {
    final db = await AppDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query('Productos');

    return List.generate(maps.length, (i) {
      return ProductsModel(
        id: maps[i]['id'],
        ISBN: maps[i]['ISBN'],
        EAN: maps[i]['EAN'],
        referencia: maps[i]['Referencia'],
        descReferencia: maps[i]['Desc_Referencia'],
        precio: maps[i]['Precio'],
        cantidad: maps[i]['Cantidad'],
        autor: maps[i]['Autor'],
        selloEditorial: maps[i]['Sello_Editorial'],
        familia: maps[i]['Familia'],
      );
    });
  }

  // funcion para obtener los registros donde el mnube sea 0
  Future<List<ProductsModel>> getProductsByMnube() async {
    final db = await AppDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Productos',
      where: 'mnube = ?',
      whereArgs: [0],
    );

    return List.generate(maps.length, (i) {
      return ProductsModel.fromMap(maps[i]);
    });
  }

  Future<int> getCountProductosNoNube() async {
    final db = await AppDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Productos',
      where: 'mnube = ?',
      whereArgs: [0],
    );

    return maps.length;
  }

  Future<List<ProductsModel>> getProductsNotSynced() async {
    final db = await AppDatabase.database;
    final List<Map<String, dynamic>> result = await db.query(
      'Productos',
      where: 'mnube = ?',
      whereArgs: [0],
    );

    return result.map((map) => ProductsModel.fromMap(map)).toList();
  }

  Future<void> updateProducto(dynamic id) async {
    final db = await AppDatabase.database;
    final result = await db.update(
      'productos',
      {'mnube': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
    print('Filas afectadas en productos: $result');
  }
}

class ProductsDaoEspecials {
  Future<int> insertProductsEspecials(ProductsEspecialsModel especials) async {
    final db = await AppDatabase.database;
    return await db.insert('Productos_Especiales', {
      'id': especials.id,
      'Referencia': especials.referencia,
      'Desc_Referencia': especials.descReferencia,
      'Porcentaje_Descuento': especials.porcentajeDescuento,
      'Precio': especials.precio,
      'Acumula': especials.acumula,
      'Acumula_Obsequio': especials.acumulaObsequio,
      'Usuario': especials.usuario,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}

class ProductsPaquetesDao {
  Future<int> insertProductPaquete(ProductsPaquetesModel paquete) async {
    final db = await AppDatabase.database;
    return await db.insert('Productos_Paquetes', {
      'id': paquete.id,
      'Codigo_Paquete': paquete.codigoPaquete,
      'Codigo_Ean': paquete.codigoEan,
      'Referencia': paquete.referencia,
      'Desc_Referencia': paquete.descReferencia,
      'Precio': paquete.precio,
      'Usuario': paquete.usuario,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
