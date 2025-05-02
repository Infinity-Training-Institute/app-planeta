import 'package:app_planeta/infrastructure/local_db/dao/index.dart';
import 'package:app_planeta/infrastructure/local_db/models/products_model.dart';

class AddNewProductService {
  final ProductsDao _productsDao = ProductsDao();

  Future<void> addProduct({
    required String referencia,
    required String ean,
    required String nombreLibro,
    required double precio,
  }) async {
    final product = ProductsModel(
      ISBN: '', // Si tienes este dato, agrégalo
      EAN: ean,
      referencia: referencia,
      descReferencia: nombreLibro,
      precio: precio.toInt(),
      cantidad: 999,
      autor: '',
      selloEditorial: '',
      familia: 0,
      mnube: 0
    );

    await _productsDao.insertProduct(product);
  }
}
