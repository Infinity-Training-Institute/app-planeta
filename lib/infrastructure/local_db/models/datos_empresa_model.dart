class DatosEmpresaModel {
  final int? id;
  final String nombreEmpresa;
  final String nit;
  final String direccion;
  final String telefono;
  final String email;
  final int logo;

  DatosEmpresaModel({
    this.id,
    required this.nombreEmpresa,
    required this.nit,
    required this.direccion,
    required this.telefono,
    required this.email,
    required this.logo,
  });

  // Convertir un objeto a un mapa
  Map<String, dynamic> toMap() {
    return {
      'Id': id,
      'Nombre_Empresa': nombreEmpresa,
      'Nit': nit,
      'Direccion': direccion,
      'Telefono': telefono,
      'Email': email,
      'Logo': logo,
    };
  }

  // Convertir un mapa a un objeto con valores seguros
  factory DatosEmpresaModel.fromMap(Map<String, dynamic> map) {
    return DatosEmpresaModel(
      id: map['Id'] as int?,
      nombreEmpresa: map['Nombre_Empresa'] ?? '',
      nit: map['Nit'] ?? '',
      direccion: map['Direccion'] ?? '',
      telefono: map['Telefono'] ?? '',
      email: map['Email'] ?? '',
      logo: map['Logo'] ?? '',
    );
  }
}
