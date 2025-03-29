class UserModel {
  final int? codUsuario;
  final String nombreUsuario;
  final String apellidoUsuario;
  final String nickUsuario;
  final String pwdUsuario;
  final int tipoUsuario;
  final int estadoUsuario;
  final String serieImpUsuario;
  final int facturaAlternaUsuario;
  final String cajaUsuario;
  final String? stand;

  UserModel({
    this.codUsuario,
    required this.nombreUsuario,
    required this.apellidoUsuario,
    required this.nickUsuario,
    required this.pwdUsuario,
    required this.tipoUsuario,
    required this.estadoUsuario,
    required this.serieImpUsuario,
    required this.facturaAlternaUsuario,
    required this.cajaUsuario,
    this.stand,
  });

  // Convertir un objeto a un mapa
  Map<String, dynamic> toMap() {
    return {
      'codUsuario': codUsuario,
      'nombreUsuario': nombreUsuario,
      'apellidoUsuario': apellidoUsuario,
      'nickUsuario': nickUsuario,
      'pwdUsuario': pwdUsuario,
      'tipoUsuario': tipoUsuario,
      'estadoUsuario': estadoUsuario,
      'serieImpUsuario': serieImpUsuario,
      'facturaAlternaUsuario': facturaAlternaUsuario,
      'cajaUsuario': cajaUsuario,
      'stand': stand,
    };
  }

  // Convertir un mapa a un objeto con valores seguros
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      codUsuario: map['Cod_Usuario'] as int?, // Permitir nulos
      nombreUsuario: map['Nombre_Usuario'] ?? '', // Evita null en String
      apellidoUsuario: map['Apellido_Usuario'] ?? '',
      nickUsuario: map['Nick_Usuario'] ?? '',
      pwdUsuario: map['Pwd_Usuario'] ?? '',
      tipoUsuario: (map['Tipo_Usuario'] ?? 0) as int, // Evita null en int
      estadoUsuario: (map['Estado_Usuario'] ?? 0) as int,
      serieImpUsuario: map['Serie_Imp_Usuario'] ?? '',
      facturaAlternaUsuario: (map['Factura_Alterna_Usuario'] ?? 0) as int,
      cajaUsuario: map['Caja_Usuario'] ?? '',
      stand: map['Stand']?.toString(), // Permitir nulos
    );
  }
}
