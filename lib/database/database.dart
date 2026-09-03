import 'package:drift/drift.dart';
import 'package:drift/web.dart';

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [
  Customers,
  Products,
  Suppliers,
  Invoices,
  InvoiceItems,
  InventoryTransactions,
  LedgerEntries,
  SyncQueueTable,
  CaretEntries,
  PurchaseLots,
  SaleLines,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  static QueryExecutor _openConnection() {
    return WebDatabase('nexon_erp_db');
  }

  // Sync queue operations
  Future<List<SyncQueueTableData>> getPendingSyncEntries() {
    return (select(syncQueueTable)..where((s) => s.status.equals('pending'))).get();
  }

  Future<int> deleteSyncQueueEntry(String id) {
    return (delete(syncQueueTable)..where((s) => s.id.equals(id))).go();
  }
}