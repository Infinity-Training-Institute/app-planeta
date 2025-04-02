class TextFacturaModel {
  final int? id;
  final String descripcion;

  TextFacturaModel({this.id, required this.descripcion});

  // convertirmos un objeto a un mapa
  Map<String, dynamic> toMap() {
    return {'id': id, 'descripcion': descripcion};
  }

  // convertimos un mapa a un objeto de valores
  factory TextFacturaModel.fromMap(Map<String, dynamic> map) {
    return TextFacturaModel(
      id: map['id'] as int?,
      descripcion: map['descripcion'] ?? '',
    );
  }
}
