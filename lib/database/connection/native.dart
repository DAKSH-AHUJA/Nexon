import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Opens a connection to the local SQLite database using the native sqlite3
/// libraries bundled by `sqlite3_flutter_libs`.
QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'nexon_erp_db.sqlite3'));
    return NativeDatabase.createInBackground(file);
  });
}
