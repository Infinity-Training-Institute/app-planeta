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
}
