class DatosClienteModel {
  final String clcecl;
  final String clnmcl;
  final String clpacl;
  final String clsacl;
  final String clmail;
  final String cldire;
  final String clciud;
  final String cltele;
  final String clusua;
  final String cltipo;
  final String clfecha;

  DatosClienteModel({
    required this.clcecl,
    required this.clnmcl,
    required this.clpacl,
    required this.clsacl,
    required this.clmail,
    required this.cldire,
    required this.clciud,
    required this.cltele,
    required this.clusua,
    required this.cltipo,
    required this.clfecha,
  });

  // convertimos el objeto en un mapa
  Map<String, dynamic> toMap() {
    return {
      'clcecl': clcecl,
      'clnmcl': clnmcl,
      'clpacl': clpacl,
      'clsacl': clsacl,
      'clmail': clmail,
      'cldire': cldire,
      'clciud': clciud,
      'cltele': cltele,
      'clusua': clusua,
      'cltipo': cltipo,
      'clfecha': clfecha,
    };
  }

  // Convertir un mapa a un objeto con valores seguros
  factory DatosClienteModel.fromMap(Map<String, dynamic> map) {
    return DatosClienteModel(
      clcecl: map['clcecl'] ?? '',
      clnmcl: map['clnmcl'] ?? '',
      clpacl: map['clpacl'] ?? '',
      clsacl: map['clsacl'] ?? '',
      clmail: map['clmail'] ?? '',
      cldire: map['cldire'] ?? '',
      clciud: map['clciud'] ?? '',
      cltele: map['cltele'] ?? '',
      clusua: map['clusua'] ?? '',
      cltipo: map['cltipo'] ?? '',
      clfecha: map['clfecha'] ?? '',
    );
  }
}
