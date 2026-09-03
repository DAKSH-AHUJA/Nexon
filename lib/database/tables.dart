import 'package:drift/drift.dart';

class Customers extends Table {
  TextColumn get id => text().clientDefault(() => 'cust_${DateTime.now().millisecondsSinceEpoch}')();
  TextColumn get name => text()();
  TextColumn get phone => text()();
  TextColumn get email => text().withDefault(const Constant(''))();
  TextColumn get gst => text().withDefault(const Constant(''))();
  TextColumn get address => text().withDefault(const Constant(''))();
  TextColumn get city => text().withDefault(const Constant(''))();
  RealColumn get outstandingBalance => real().withDefault(const Constant(0))();
  RealColumn get totalPurchases => real().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('active'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class Products extends Table {
  TextColumn get id => text().clientDefault(() => 'prod_${DateTime.now().millisecondsSinceEpoch}')();
  TextColumn get name => text()();
  TextColumn get category => text()();
  TextColumn get unit => text().withDefault(const Constant('kg'))();
  RealColumn get currentStock => real().withDefault(const Constant(0))();
  RealColumn get purchasePrice => real().withDefault(const Constant(0))();
  RealColumn get sellingPrice => real().withDefault(const Constant(0))();
  RealColumn get minimumStock => real().withDefault(const Constant(0))();
  TextColumn get description => text().withDefault(const Constant(''))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class Suppliers extends Table {
  TextColumn get id => text().clientDefault(() => 'sup_${DateTime.now().millisecondsSinceEpoch}')();
  TextColumn get name => text()();
  TextColumn get phone => text()();
  TextColumn get email => text().withDefault(const Constant(''))();
  TextColumn get gst => text().withDefault(const Constant(''))();
  TextColumn get address => text().withDefault(const Constant(''))();
  TextColumn get city => text().withDefault(const Constant(''))();
  RealColumn get outstandingPayment => real().withDefault(const Constant(0))();
  RealColumn get totalPurchases => real().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('active'))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class Invoices extends Table {
  TextColumn get id => text().clientDefault(() => 'inv_${DateTime.now().millisecondsSinceEpoch}')();
  TextColumn get invoiceNo => text()();
  TextColumn get customerId => text()();
  TextColumn get customerName => text()();
  RealColumn get subtotal => real().withDefault(const Constant(0))();
  RealColumn get totalGst => real().withDefault(const Constant(0))();
  RealColumn get grandTotal => real().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class InvoiceItems extends Table {
  TextColumn get id => text().clientDefault(() => 'item_${DateTime.now().millisecondsSinceEpoch}')();
  TextColumn get invoiceId => text()();
  TextColumn get productId => text()();
  TextColumn get productName => text()();
  RealColumn get quantity => real()();
  RealColumn get price => real()();
  RealColumn get discount => real().withDefault(const Constant(0))();
  RealColumn get gstRate => real().withDefault(const Constant(5))();

  @override
  Set<Column> get primaryKey => {id};
}

class InventoryTransactions extends Table {
  TextColumn get id => text().clientDefault(() => 'txn_${DateTime.now().millisecondsSinceEpoch}')();
  TextColumn get productId => text()();
  TextColumn get productName => text()();
  TextColumn get type => text()();
  RealColumn get quantity => real()();
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
  TextColumn get note => text().withDefault(const Constant(''))();
  TextColumn get user => text().withDefault(const Constant('Admin'))();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class LedgerEntries extends Table {
  TextColumn get id => text().clientDefault(() => 'ledger_${DateTime.now().millisecondsSinceEpoch}')();
  TextColumn get customerId => text()();
  TextColumn get description => text()();
  RealColumn get debit => real().withDefault(const Constant(0))();
  RealColumn get credit => real().withDefault(const Constant(0))();
  RealColumn get balance => real()();
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class CaretEntries extends Table {
  TextColumn get id => text().clientDefault(() => 'caret_${DateTime.now().millisecondsSinceEpoch}')();
  TextColumn get companyId => text()();
  TextColumn get partyId => text()();
  TextColumn get partyName => text()();
  TextColumn get type => text()();
  IntColumn get quantity => integer()();
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
  TextColumn get referenceNumber => text().nullable()();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class PurchaseLots extends Table {
  TextColumn get id => text().clientDefault(() => 'lot_${DateTime.now().millisecondsSinceEpoch}')();
  IntColumn get srNo => integer()();
  DateTimeColumn get date => dateTime()();
  TextColumn get partyName => text()();
  TextColumn get item => text()();
  RealColumn get bags => real()();
  RealColumn get totalCarets => real().withDefault(const Constant(0))();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class SaleLines extends Table {
  TextColumn get id => text().clientDefault(() => 'sale_${DateTime.now().millisecondsSinceEpoch}')();
  TextColumn get lotId => text()();
  IntColumn get billNo => integer()();
  DateTimeColumn get date => dateTime()();
  TextColumn get partyName => text()();
  RealColumn get bags => real()();
  RealColumn get weight => real()();
  RealColumn get rate => real()();
  TextColumn get unit => text().withDefault(const Constant('1KG'))();

  @override
  Set<Column> get primaryKey => {id};
}

class SyncQueueTable extends Table {
  TextColumn get id => text().clientDefault(() => 'sync_${DateTime.now().millisecondsSinceEpoch}')();
  TextColumn get tableNameCol => text()();
  TextColumn get recordId => text()();
  TextColumn get operation => text()();
  TextColumn get data => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}