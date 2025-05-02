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
  final String cl_nube;
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
    required this.cl_nube,
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
      'cl_nube': cl_nube,
      'clusua': clusua,
      'cltipo': cltipo,
      'clfecha': clfecha,
    };
  }

  // Convertir un mapa a un objeto con valores seguros
  factory DatosClienteModel.fromMap(Map<String, dynamic> map) {
    return DatosClienteModel(
      clcecl: map['clcecl'],
      clnmcl: map['clnmcl']?.toString() ?? '',
      clpacl: map['clpacl']?.toString() ?? '',
      clsacl: map['clsacl']?.toString() ?? '',
      clmail: map['clmail']?.toString() ?? '',
      cldire: map['cldire']?.toString() ?? '',
      clciud: map['clciud']?.toString() ?? '',
      cltele: map['cltele']?.toString() ?? '',
      cl_nube: map['cl_nube']?.toString() ?? '',
      clusua: map['clusua']?.toString() ?? '',
      cltipo: map['cltipo']?.toString() ?? '',
      clfecha: map['clfecha']?.toString() ?? '',
    );
  }

  // Convertir un objeto a una cadena JSON
  Map<String, dynamic> toJson() {
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
      'cl_nube': cl_nube, // Manejar el campo cl_nube
      'cltipo': cltipo,
      'clfecha': clfecha,
    };
  }
}
