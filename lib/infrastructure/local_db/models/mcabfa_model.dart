class McabfaModel {
  final int? mcnufa;
  final String mcnuca;
  final int mccecl;
  final int mcfefa;
  final String mchora;
  final String mcfopa;
  final int mcpode;
  final int mcvade;
  final String mctifa;
  final int mcvabr;
  final int mcvane;
  final String mcesta;
  final String? mc_connotacre;
  final int mcvaef;
  final int mcvach;
  final int mcvata;
  final int mcvabo;
  final int mctobo;
  final String mcnubo;
  final String mcusua;
  final String mcusan;
  final int mchoan;
  final String mcnuau;
  final int mcnufi;
  final String mccaja;
  final String mcufe;
  final int mstand;
  final int mnube;

  McabfaModel({
    required this.mcnufa,
    required this.mcnuca,
    this.mc_connotacre,
    required this.mccecl,
    required this.mcfefa,
    required this.mchora,
    required this.mcfopa,
    required this.mcpode,
    required this.mcvade,
    required this.mctifa,
    required this.mcvabr,
    required this.mcvane,
    required this.mcesta,
    required this.mcvaef,
    required this.mcvach,
    required this.mcvata,
    required this.mcvabo,
    required this.mctobo,
    required this.mcnubo,
    required this.mcusua,
    required this.mcusan,
    required this.mchoan,
    required this.mcnuau,
    required this.mcnufi,
    required this.mccaja,
    required this.mcufe,
    required this.mstand,
    required this.mnube,
  });

  // Convertir un objeto a un mapa
  Map<String, dynamic> toMap() {
    return {
      'mcnufa': mcnufa,
      'mcnuca': mcnuca,
      'mccecl': mccecl,
      'mcfefa': mcfefa,
      'mchora': mchora,
      'mcfopa': mcfopa,
      'mcpode': mcpode,
      'mcvade': mcvade,
      'mctifa': mctifa,
      'mcvabr': mcvabr,
      'mcvane': mcvane,
      'mcesta': mcesta,
      'mcvaef': mcvaef,
      'mcvach': mcvach,
      'mcvata': mcvata,
      'mcvabo': mcvabo,
      'mctobo': mctobo,
      'mcnubo': mcnubo,
      'mcusua': mcusua,
      'mcusan': mcusan,
      'mchoan': mchoan,
      'mcnuau': mcnuau,
      'mcnufi': mcnufi,
      'mccaja': mccaja,
      'mcufe': mcufe,
      'mstand': mstand,
      'mnube': mnube,
    };
  }

  // Convertir un mapa a un objeto con valores seguros
  factory McabfaModel.fromMap(Map<String, dynamic> map) {
    return McabfaModel(
      mcnufa: map['mcnufa'] as int?,
      mcnuca: map['mcnuca'] ?? '',
      mccecl: (map['mccecl'] ?? 0) as int,
      mcfefa: (map['mcfefa'] ?? 0) as int,
      mchora: map['mchora'] ?? '',
      mcfopa: map['mcfopa'] ?? '',
      mcpode: (map['mcpode'] ?? 0) as int,
      mcvade: (map['mcvade'] ?? 0) as int,
      mctifa: map['mctifa'] ?? '',
      mcvabr: (map['mcvabr'] ?? 0) as int,
      mcvane: (map['mcvane'] ?? 0) as int,
      mcesta: map['mcesta'] ?? '',
      mcvaef: (map['mcvaef'] ?? 0) as int,
      mcvach: (map['mcvach'] ?? 0) as int,
      mcvata: (map['mcvata'] ?? 0) as int,
      mcvabo: (map['mcvabo'] ?? 0) as int,
      mctobo: (map['mctobo'] ?? 0) as int,
      mcnubo: map['mcnubo'] ?? '',
      mcusua: map['mcusua'] ?? '',
      mcusan: map['mcusan'] ?? '',
      mchoan: (map['mchoan'] ?? 0) as int,
      mcnuau: map['mcnuau'] ?? '',
      mcnufi: (map['mcnufi'] ?? 0) as int,
      mccaja: map['mccaja'] ?? '',
      mcufe: map['mcufe'] ?? '',
      mstand: (map['mstand'] ?? 0) as int,
      mnube: (map['mnube'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toJson() => {
    "mcnufa": mcnufa,
    "mcnuca": mcnuca,
    "mccecl": mccecl,
    "mcfefa": mcfefa,
    "mchora": mchora,
    "mcfopa": mcfopa,
    "mcpode": mcpode,
    "mcvade": mcvade,
    "mctifa": mctifa,
    "mcvabr": mcvabr,
    "mcvane": mcvane,
    "mcesta": mcesta,
    "mc_connotacre": mc_connotacre,
    "mcvaef": mcvaef,
    "mcvach": mcvach,
    "mcvata": mcvata,
    "mcvabo": mcvabo,
    "mctobo": mctobo,
    "mcnubo": mcnubo,
    "mcusua": mcusua,
    "mcusan": mcusan,
    "mchoan": mchoan,
    "mcnuau": mcnuau,
    "mcnufi": mcnufi,
    "mccaja": mccaja,
    "mcufe": mcufe,
    "mstand": mstand,
    "mcomfiar": 0,
    "mcomfiar_credito": 0,
    "mnube": mnube,
  };
}
