import 'package:app_planeta/infrastructure/local_db/app_database.dart';
import 'package:app_planeta/infrastructure/local_db/models/mcabfa_model.dart';
import 'package:sqflite/sql.dart';

class DatosMcabfaDao {
  Future<int> insertMcabfa(McabfaModel mcabfa) async {
    final db = await AppDatabase.database;
    return await db.insert("mcabfa", {
      "mcnufa": mcabfa.mcnufa,
      "mcnuca": mcabfa.mcnuca,
      "mccecl": mcabfa.mccecl,
      "mcfefa": mcabfa.mcfefa,
      "mchora": mcabfa.mchora,
      "mcfopa": mcabfa.mcfopa,
      "mcpode": mcabfa.mcpode,
      "mcvade": mcabfa.mcvade,
      "mctifa": mcabfa.mctifa,
      "mcvabr": mcabfa.mcvabr,
      "mcvane": mcabfa.mcvane,
      "mcesta": mcabfa.mcesta,
      "mcvaef": mcabfa.mcvaef,
      "mcvach": mcabfa.mcvach,
      "mcvata": mcabfa.mcvata,
      "mcvabo": mcabfa.mcvabo,
      "mctobo": mcabfa.mctobo,
      "mcnubo": mcabfa.mcnubo,
      "mcusua": mcabfa.mcusua,
      "mcusan": mcabfa.mcusan,
      "mchoan": mcabfa.mchoan,
      "mcnuau": mcabfa.mcnuau,
      "mcnufi": mcabfa.mcnufi,
      "mccaja": mcabfa.mccaja,
      "mcufe": mcabfa.mcufe,
      "mstand": mcabfa.mstand,
      "mnube": mcabfa.mnube
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // funcion para obtener todo
  Future<List<McabfaModel>> getAllMcabfa() async {
    final db = await AppDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query("mcabfa");
    return List.generate(maps.length, (i) {
      return McabfaModel(
        mcnufa: maps[i]["mcnufa"],
        mcnuca: maps[i]["mcnuca"],
        mccecl: maps[i]["mccecl"],
        mcfefa: maps[i]["mcfefa"],
        mchora: maps[i]["mchora"],
        mcfopa: maps[i]["mcfopa"],
        mcpode: maps[i]["mcpode"],
        mcvade: maps[i]["mcvade"],
        mctifa: maps[i]["mctifa"],
        mcvabr: maps[i]["mcvabr"],
        mcvane: maps[i]["mcvane"],
        mcesta: maps[i]["mcesta"],
        mcvaef: maps[i]["mcvaef"],
        mcvach: maps[i]["mcvach"],
        mcvata: maps[i]["mcvata"],
        mcvabo: maps[i]["mcvabo"],
        mctobo: maps[i]["mctobo"],
        mcnubo: maps[i]["mcnubo"],
        mcusua: maps[i]["mcusua"],
        mcusan: maps[i]["mcusan"],
        mchoan: maps[i]["mchoan"],
        mcnuau: maps[i]["mcnuau"],
        mcnufi: maps[i]["mcnufi"],
        mccaja: maps[i]["mccaja"],
        mcufe: maps[i]["mcufe"],
        mstand: maps[i]["mstand"],
        mnube: maps[i]["mnube"]
      );
    });
  }

  // funcion para un count
  Future<int> getCountMcabfa() async {
    final db = await AppDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query("mcabfa");
    return maps.length;
  }
}
