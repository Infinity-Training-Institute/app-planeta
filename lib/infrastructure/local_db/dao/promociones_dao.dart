import 'package:app_planeta/infrastructure/local_db/app_database.dart';
import 'package:app_planeta/infrastructure/local_db/models/promociones_model.dart';
import 'package:sqflite/sqflite.dart';

class PromocionesDao {
  Future<int> insertPromocion(PromocionesModel promocion) async {
    final db = await AppDatabase.database;
    return await db.insert('Promociones', {
      'Cod_Promocion': promocion.codPromocion,
      'Fecha_Promocion': promocion.fechaPromocion,
      'Hora_Desde': promocion.horaDesde,
      'Hora_Hasta': promocion.horaHasta,
      'Minuto_Hasta': promocion.minutoHasta,
      'Usuario': promocion.usuario,
      'Tipo_Promocion': promocion.tipoPromocion,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> countPromociones() async {
    final db = await AppDatabase.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM Promociones');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> deleteAll() async {
    final db = await AppDatabase.database;
    await db.delete('Promociones');
  }
}

class PromocionHoraDao {
  Future<int> inserPromocionHora(PromocionHorasModel promocionHoras) async {
    final db = await AppDatabase.database;
    return await db.insert('Promocion_Horas', {
      'Cod_Promocion': promocionHoras.codPromocion,
      'Fecha_Promocion': promocionHoras.fechaPromocion,
      'Hora_Desde': promocionHoras.horaDesde,
      'Minuto_Desde': promocionHoras.minutoDesde,
      'Hora_Hasta': promocionHoras.horaHasta,
      'Minuto_Hasta': promocionHoras.minutoHasta,
      'Descuento_Promocion': promocionHoras.descuentoPromocion,
      'Usuario': promocionHoras.usuario,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> countPromocionHoras() async {
    final db = await AppDatabase.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM Promocion_Horas');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> deleteAll() async {
    final db = await AppDatabase.database;
    await db.delete('Promocion_Horas');
  }
}

class PromocionCantidadDao {
  Future<int> insertPromocionCantidad(
    PromocionCantidadModel promocionCantidad,
  ) async {
    final db = await AppDatabase.database;
    return await db.insert('Promocion_Cantidad', {
      'Cod_Promocion': promocionCantidad.codPromocion,
      'Productos_Desde': promocionCantidad.productosDesde,
      'Productos_Hasta': promocionCantidad.productosHasta,
      'Porcentaje_Descuento': promocionCantidad.porcentajeDescuento,
      'Obsequio': promocionCantidad.obsequio,
      'Usuario': promocionCantidad.usuario,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> countPromocionCantidad() async {
    final db = await AppDatabase.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM Promocion_Cantidad');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> deleteAll() async {
    final db = await AppDatabase.database;
    await db.delete('Promocion_Cantidad');
  }
}
