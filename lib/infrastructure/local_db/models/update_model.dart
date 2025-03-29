class UpdateModel {
  final int? id;
  final String fechaActualizacion;

  UpdateModel({this.id, required this.fechaActualizacion});

  // convertimos un objeto a un mapa
  Map<String, dynamic> toMap() {
    return {'id': id, 'fechaActualizacion': fechaActualizacion};
  }

  // convertimos un mapa a un objeto con valores seguros
  factory UpdateModel.fromMap(Map<String, dynamic> map) {
    return UpdateModel(
      id: map['id'] as int?,
      fechaActualizacion: map['fecha_actualizacion'] ?? '',
    );
  }
}
