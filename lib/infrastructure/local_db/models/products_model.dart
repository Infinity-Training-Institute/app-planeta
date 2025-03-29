class ProductsModel {
  final int? id;
  final String ISBN;
  final String EAN;
  final String referencia;
  final String descReferencia;
  final int precio;
  final int cantidad;
  final String autor;
  final String selloEditorial;
  final int familia;

  ProductsModel({
    this.id,
    required this.ISBN,
    required this.EAN,
    required this.referencia,
    required this.descReferencia,
    required this.precio,
    required this.cantidad,
    required this.autor,
    required this.selloEditorial,
    required this.familia,
  });

  // Convertir un objeto a un mapa
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ISBN': ISBN,
      'EAN': EAN,
      'Referencia': referencia,
      'Desc_Referencia': descReferencia,
      'Precio': precio,
      'Cantidad': cantidad,
      'Autor': autor,
      'Sello_Editorial': selloEditorial,
      'Familia': familia,
    };
  }

  // Convertir un mapa a un objeto con valores seguros
  factory ProductsModel.fromMap(Map<String, dynamic> map) {
    return ProductsModel(
      id: map['id'] as int?,
      ISBN: map['ISBN'] ?? '',
      EAN: map['EAN'] ?? '',
      referencia: map['Referencia'] ?? '',
      descReferencia: map['Desc_Referencia'] ?? '',
      precio: (map['Precio'] ?? 0) as int,
      cantidad: (map['Cantidad'] ?? 0) as int,
      autor: map['Autor'] ?? '',
      selloEditorial: map['Sello_Editorial'] ?? '',
      familia: (map['Familia'] ?? 0) as int,
    );
  }
}

class ProductsEspecialsModel {
  final int? id;
  final String referencia;
  final String descReferencia;
  final int? porcentajeDescuento;
  final int precio;
  final String acumula;
  final String acumulaObsequio;
  final String usuario;

  ProductsEspecialsModel({
    required this.id,
    required this.referencia,
    required this.descReferencia,
    required this.porcentajeDescuento,
    required this.precio,
    required this.acumula,
    required this.acumulaObsequio,
    required this.usuario,
  });

  // convertimos el objeto en un mapa
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'referencia': referencia,
      'Desc_Referencia': descReferencia,
      'Porcentaje_Descuento': porcentajeDescuento,
      'Precio': precio,
      'Acumula': acumula,
      'Acumula_Obsequio': acumulaObsequio,
      'Usuario': usuario,
    };
  }

  // Convertir un mapa a un objeto con valores seguros
  factory ProductsEspecialsModel.fromMap(Map<String, dynamic> map) {
    return ProductsEspecialsModel(
      id: map['id'] as int?,
      referencia: map['Referencia'],
      descReferencia: map['Desc_Referencia'],
      porcentajeDescuento: map['Porcentaje_Descuento'],
      precio: map['Precio'],
      acumula: map['Acumula'],
      acumulaObsequio: map['Acumula_Obsequio'],
      usuario: map['Usuario'],
    );
  }
}

class ProductsPaquetesModel {
  final int? id;
  final int? codigoPaquete;
  final String codigoEan;
  final String referencia;
  final String descReferencia;
  final int? precio;
  final String usuario;

  ProductsPaquetesModel({
    required this.id,
    required this.codigoPaquete,
    required this.codigoEan,
    required this.referencia,
    required this.descReferencia,
    required this.precio,
    required this.usuario,
  });

  // convertimos el objeto en un mapa
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'Codigo_Paquete': codigoPaquete,
      'Codigo_Ean': codigoEan,
      'Referencia': referencia,
      'Descripcion_Referencia': descReferencia,
      'Precio': precio,
      'Usuario': usuario,
    };
  }

  // Convertir un mapa a un objeto con valores seguros
  factory ProductsPaquetesModel.fromMap(Map<String, dynamic> map) {
    return ProductsPaquetesModel(
      id: map['id'] as int?,
      codigoPaquete: map['Codigo_Paquete'],
      codigoEan: map['Codigo_Ean'],
      referencia: map['Referencia'],
      descReferencia: map['Descripcion_Referencia'],
      precio: map['Precio'],
      usuario: map['Usuario'],
    );
  }
}
