class DatosCajaModel {
  final int? codCaja;
  final String stand;
  final String numeroCaja;
  final String facturaInicio;
  final String numeroResolucion;
  final String facturaActual;
  final String nickUsuario;
  final String claveTecnica;

  DatosCajaModel({
    this.codCaja,
    required this.stand,
    required this.numeroCaja,
    required this.facturaInicio,
    required this.numeroResolucion,
    required this.facturaActual,
    required this.nickUsuario,
    required this.claveTecnica,
  });

  // Convertir un objeto a un mapa
  Map<String, dynamic> toMap() {
    return {
      'Cod_Caja': codCaja,
      'Stand': stand,
      'Numero_Caja': numeroCaja,
      'Factura_Inicio': facturaInicio,
      'Numero_Resolucion': numeroResolucion,
      'Factura_Actual': facturaActual,
      'Nick_Usuario': nickUsuario,
      'Clave_Tecnica': claveTecnica,
    };
  }

  // Convertir un mapa a un objeto con valores seguros
  factory DatosCajaModel.fromMap(Map<String, dynamic> map) {
    return DatosCajaModel(
      codCaja: map['Cod_Caja'] as int?,
      stand: map['Stand'] ?? '',
      numeroCaja: map['Numero_Caja'] ?? '',
      facturaInicio: map['Factura_Inicio'] ?? '',
      numeroResolucion: map['Numero_Resolucion'] ?? '',
      facturaActual: map['Factura_Actual'] ?? '',
      nickUsuario: map['Nick_Usuario'] ?? '',
      claveTecnica: map['Clave_Tecnica'] ?? '',
    );
  }
}
