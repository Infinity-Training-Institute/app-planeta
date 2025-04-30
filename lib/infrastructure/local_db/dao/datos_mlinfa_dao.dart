import 'package:app_planeta/infrastructure/local_db/app_database.dart';
import 'package:app_planeta/infrastructure/local_db/models/mlinfa_model.dart';
import 'package:sqflite/sql.dart';

class DatosMlinfaDao {
  Future<int> insertMlinfa(MlinfaModel mlinfa) async {
    final db = await AppDatabase.database;
    return await db.insert("mlinfa", {
      "mlnufc": mlinfa.mlnufc,
      "mlnuca": mlinfa.mlnuca,
      "mlcdpr": mlinfa.mlcdpr,
      "mlnmpr": mlinfa.mlnmpr,
      "mlpvpr": mlinfa.mlpvpr,
      "mlpvne": mlinfa.mlpvne,
      "mlcant": mlinfa.mlcant,
      "mlesta": mlinfa.mlesta,
      "mlestao": mlinfa.mlestao,
      "mlfefa": mlinfa.mlfefa,
      "mlestf": mlinfa.mlestf,
      "mlusua": mlinfa.mlusua,
      "mlnufi": mlinfa.mlnufi,
      "mlcaja": mlinfa.mlcaja,
      "mstand": mlinfa.mstand,
      "mnube": mlinfa.mnube,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // funcion para obtener todo
  Future<List<MlinfaModel>> getAllMlinfa() async {
    final db = await AppDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query("mlinfa");
    return List.generate(maps.length, (i) {
      return MlinfaModel(
        mlnufc: maps[i]["mlnufc"],
        mlnuca: maps[i]["mlnuca"],
        mlcdpr: maps[i]["mlcdpr"],
        mlnmpr: maps[i]["mlnmpr"],
        mlpvpr: maps[i]["mlpvpr"],
        mlpvne: maps[i]["mlpvne"],
        mlcant: maps[i]["mlcant"],
        mlesta: maps[i]["mlesta"],
        mlestao: maps[i]["mlestao"],
        mlfefa: maps[i]["mlfefa"],
        mlestf: maps[i]["mlestf"],
        mlusua: maps[i]["mlusua"],
        mlnufi: maps[i]["mlnufi"],
        mlcaja: maps[i]["mlcaja"],
        mstand: maps[i]["mstand"],
        mnube: maps[i]["mnube"],
      );
    });
  }

  // funcion para un count donde el mnube sea 0
  Future<int> getCountMlinfa() async {
    final db = await AppDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'mlinfa',
      where: 'mnube = ?',
      whereArgs: [0],
    );

    return maps.length;
  }

  // actualizamos el mnube a 1 en la base de datos
  Future<void> updateMnube(int mcnufa) async {
    final db = await AppDatabase.database;
    await db.update(
      'mlinfa',
      {'mnube': 1},
      where: 'mcnufa = ?',
      whereArgs: [mcnufa],
    );
  }
}
