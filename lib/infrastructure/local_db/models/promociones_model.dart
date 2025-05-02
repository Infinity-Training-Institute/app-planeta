class PromocionesModel {
  final int? codPromocion;
  final String? fechaPromocion;
  final String? horaDesde;
  final String? minutoDesde;
  final String? horaHasta;
  final String? minutoHasta;
  final String? usuario;
  final String? tipoPromocion;

  PromocionesModel({
    required this.codPromocion,
    required this.fechaPromocion,
    required this.horaDesde,
    required this.minutoDesde,
    required this.horaHasta,
    required this.minutoHasta,
    required this.usuario,
    required this.tipoPromocion,
  });

  // Convertimos el objeto en un mapa
  Map<String, dynamic> toMap() {
    return {
      'Cod_Promocion': codPromocion,
      'Fecha_Promocion': fechaPromocion,
      'Hora_Desde': horaDesde,
      'Minuto_Desde': minutoDesde,
      'Hora_Hasta': horaHasta,
      'Minuto_Hasta': minutoHasta,
      'Usuario': usuario,
      'Tipo_Promocion': tipoPromocion,
    };
  }

  // Convertir un mapa a un objeto con valores seguros
  factory PromocionesModel.fromMap(Map<String, dynamic> map) {
    return PromocionesModel(
      codPromocion: map['Cod_Promocion'] as int?,
      fechaPromocion: map['Fecha_Promocion'],
      horaDesde: map['Hora_Desde'],
      minutoDesde: map['Minuto_Desde'],
      horaHasta: map['Hora_Hasta'],
      minutoHasta: map['Minuto_Hasta'],
      usuario: map['Usuario'],
      tipoPromocion: map['Tipo_Promocion'],
    );
  }

  @override
  String toString() {
    return 'PromocionesModel{Cod_Promocion: $codPromocion, Fecha_Promocion: $fechaPromocion, Hora_Desde: $horaDesde, Hora_Hasta: $horaHasta, Minuto_Hasta: $minutoHasta, Usuario: $usuario, Tipo_Promocion: $tipoPromocion}';
  }
}

class PromocionHorasModel {
  final int? codPromocion;
  final String? fechaPromocion;
  final String? horaDesde;
  final String? minutoDesde;
  final String? horaHasta;
  final String? minutoHasta;
  final String? descuentoPromocion;
  final String? usuario;

  PromocionHorasModel({
    required this.codPromocion,
    required this.fechaPromocion,
    required this.horaDesde,
    required this.minutoDesde,
    required this.horaHasta,
    required this.minutoHasta,
    required this.descuentoPromocion,
    required this.usuario,
  });

  // Convertimos el objeto en un mapa
  Map<String, dynamic> toMap() {
    return {
      'Cod_Promocion': codPromocion,
      'Fecha_Promocion': fechaPromocion,
      'Hora_Desde': horaDesde,
      'Minuto_Desde': minutoDesde,
      'Hora_Hasta': horaHasta,
      'Minuto_Hasta': minutoHasta,
      'Descuento_Promocion': descuentoPromocion,
      'Usuario': usuario,
    };
  }

  // Convertir un mapa a un objeto con valores seguros
  factory PromocionHorasModel.fromMap(Map<String, dynamic> map) {
    return PromocionHorasModel(
      codPromocion: map['Cod_Promocion'] as int?,
      fechaPromocion: map['Fecha_Promocion'],
      horaDesde: map['Hora_Desde'],
      minutoDesde: map['Minuto_Desde'],
      horaHasta: map['Hora_Hasta'],
      minutoHasta: map['Minuto_Hasta'],
      descuentoPromocion: map['Descuento_Promocion'],
      usuario: map['Usuario'],
    );
  }

  @override
  String toString() {
    return 'PromocionHoras{Cod_Promocion: $codPromocion, Fecha_Promocion: $fechaPromocion, Hora_Desde: $horaDesde, Minuto_Desde: $minutoDesde, Hora_Hasta: $horaHasta, Minuto_Hasta: $minutoHasta, Descuento_Promocion: $descuentoPromocion, Usuario: $usuario}';
  }
}

class PromocionCantidadModel {
  final int? codPromocion;
  final int? productosDesde;
  final int? productosHasta;
  final String? porcentajeDescuento;
  final String? obsequio;
  final String? usuario;

  PromocionCantidadModel({
    required this.codPromocion,
    required this.productosDesde,
    required this.productosHasta,
    required this.porcentajeDescuento,
    required this.obsequio,
    required this.usuario,
  });

  // Convertimos el objeto en un mapa
  Map<String, dynamic> toMap() {
    return {
      'Cod_Promocion': codPromocion,
      'Productos_Desde': productosDesde,
      'Productos_Hasta': productosHasta,
      'Porcentaje_Descuento': porcentajeDescuento,
      'Obsequio': obsequio,
      'Usuario': usuario,
    };
  }

  // Convertir un mapa a un objeto con valores seguros
  factory PromocionCantidadModel.fromMap(Map<String, dynamic> map) {
    return PromocionCantidadModel(
      codPromocion: map['Cod_Promocion'] as int?,
      productosDesde: map['Productos_Desde'],
      productosHasta: map['Productos_Hasta'],
      porcentajeDescuento: map['Porcentaje_Descuento'],
      obsequio: map['Obsequio'],
      usuario: map['Usuario'],
    );
  }

  @override
  String toString() {
    return 'PromocionCantidad{Cod_Promocion: $codPromocion, Productos_Desde: $productosDesde, Productos_Hasta: $productosHasta, Porcentaje_Descuento: $porcentajeDescuento, Obsequio: $obsequio, Usuario: $usuario}';
  }
}
