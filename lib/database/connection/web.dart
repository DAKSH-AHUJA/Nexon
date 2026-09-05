import 'package:drift/drift.dart';
import 'package:drift/web.dart';

/// Opens a connection to the browser-backed database (sql.js + IndexedDB).
QueryExecutor openConnection() {
  return WebDatabase('nexon_erp_db');
}
