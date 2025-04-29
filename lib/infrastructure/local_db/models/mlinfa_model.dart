class MlinfaModel {
  final int mlnufc;
  final String mlnuca;
  final String mlcdpr;
  final String mlnmpr;
  final int mlpvpr;
  final int mlpvne;
  final int mlcant;
  final String mlesta;
  final String mlestao;
  final int mlfefa;
  final String mlestf;
  final String mlusua;
  final int mlnufi;
  final String mlcaja;
  final int mstand;
  final int mnube;

  MlinfaModel({
    required this.mlnufc,
    required this.mlnuca,
    required this.mlcdpr,
    required this.mlnmpr,
    required this.mlpvpr,
    required this.mlpvne,
    required this.mlcant,
    required this.mlesta,
    required this.mlestao,
    required this.mlfefa,
    required this.mlestf,
    required this.mlusua,
    required this.mlnufi,
    required this.mlcaja,
    required this.mstand,
    required this.mnube,
  });

  // Convertir un objeto a un mapa
  Map<String, dynamic> toMap() {
    return {
      'mlnufc': mlnufc,
      'mlnuca': mlnuca,
      'mlcdpr': mlcdpr,
      'mlnmpr': mlnmpr,
      'mlpvpr': mlpvpr,
      'mlpvne': mlpvne,
      'mlcant': mlcant,
      'mlesta': mlesta,
      'mlestao': mlestao,
      'mlfefa': mlfefa,
      'mlestf': mlestf,
      'mlusua': mlusua,
      'mlnufi': mlnufi,
      'mlcaja': mlcaja,
      'mstand': mstand,
      'mnube': mnube,
    };
  }

  // Convertir un mapa a un objeto con valores seguros
  factory MlinfaModel.fromMap(Map<String, dynamic> map) {
    return MlinfaModel(
      mlnufc: map['mlnufc'] as int? ?? 0,
      mlnuca: map['mlnuca'] as String? ?? '',
      mlcdpr: map['mlcdpr'] as String? ?? '',
      mlnmpr: map['mlnmpr'] as String? ?? '',
      mlpvpr: (map['mlpvpr'] as int?) ?? 0,
      mlpvne: (map['mlpvne'] as int?) ?? 0,
      mlcant: (map['mlcant'] as int?) ?? 0,
      mlesta: map['mlesta'] as String? ?? '',
      mlestao: map['mlestao'] as String? ?? '',
      mlfefa: (map['mlfefa'] as int?) ?? 0,
      mlestf: map['mlestf'] as String? ?? '',
      mlusua: map['mlusua'] as String? ?? '',
      mlnufi: (map['mlnufi'] as int?) ?? 0,
      mlcaja: map['mlcaja'] as String? ?? '',
      mstand: (map['mstand'] as int?) ?? 0,
      mnube: (map['mnube'] as int?) ?? 0,
    );
  }
}