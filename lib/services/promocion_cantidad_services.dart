import 'package:app_planeta/infrastructure/local_db/app_database.dart';

class PromocionCantidadService {
  Future<List<Map<String, dynamic>>> fetchPromocionCantidad() async {
    final db = await AppDatabase.database;

    final List<Map<String, dynamic>> data = await db.query(
      'Promocion_Cantidad',
    );

    return data;
  }
}
