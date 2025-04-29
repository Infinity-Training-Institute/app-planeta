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
      "mnube": mlinfa.mnube
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
