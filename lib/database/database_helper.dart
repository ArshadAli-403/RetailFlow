
// Placeholder production database_helper.dart
// NOTE: This file template was generated because the chat response length
// cannot safely contain the full source.
// Replace with subsequent generated implementation.

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static const String _dbName = 'retailflow.db';
  static const int _dbVersion = 4;

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Products
    await db.execute("""
    CREATE TABLE products(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      barcode TEXT UNIQUE,
      name TEXT NOT NULL,
      price REAL NOT NULL,
      created_at TEXT NOT NULL
    )
    """);

    // Bills
    await db.execute("""
    CREATE TABLE bills(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      customer_name TEXT NOT NULL,
      date TEXT NOT NULL,
      subtotal REAL NOT NULL,
      extra_charges REAL NOT NULL DEFAULT 0,
      grand_total REAL NOT NULL,
      product_description TEXT,
      paid_amount REAL NOT NULL DEFAULT 0,
      return_amount REAL NOT NULL DEFAULT 0
    )
    """);

    // Bill items
    await db.execute("""
    CREATE TABLE bill_items(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      bill_id INTEGER NOT NULL,
      product_id INTEGER,
      product_name TEXT NOT NULL,
      quantity INTEGER NOT NULL,
      unit TEXT NOT NULL DEFAULT 'pcs',
      unit_price REAL NOT NULL,
      total_price REAL NOT NULL,
      is_manual INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY (bill_id) REFERENCES bills(id) ON DELETE CASCADE,
      FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE SET NULL
    )
    """);

    // Extra charges
    await db.execute("""
    CREATE TABLE bill_extra_charges(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      bill_id INTEGER NOT NULL,
      title TEXT NOT NULL,
      amount REAL NOT NULL,
      FOREIGN KEY (bill_id) REFERENCES bills(id) ON DELETE CASCADE
    )
    """);

    await db.execute("CREATE INDEX idx_products_barcode ON products(barcode)");
    await db.execute("CREATE INDEX idx_bill_items_bill_id ON bill_items(bill_id)");
    await db.execute("CREATE INDEX idx_bill_extra_bill_id ON bill_extra_charges(bill_id)");
  }

  Future<void> _onUpgrade(Database db,int oldVersion,int newVersion) async {
    if (oldVersion < 2) {
      try { await db.execute("ALTER TABLE bills ADD COLUMN product_description TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE bills ADD COLUMN paid_amount REAL NOT NULL DEFAULT 0"); } catch (_) {}
      try { await db.execute("ALTER TABLE bills ADD COLUMN return_amount REAL NOT NULL DEFAULT 0"); } catch (_) {}
    }
    if (oldVersion < 3) {
      try { await db.execute("ALTER TABLE bill_items ADD COLUMN unit TEXT NOT NULL DEFAULT 'pcs'"); } catch (_) {}
      try { await db.execute("ALTER TABLE bill_items ADD COLUMN is_manual INTEGER NOT NULL DEFAULT 0"); } catch (_) {}
    }
    if (oldVersion < 4) {
      await db.execute("""CREATE TABLE IF NOT EXISTS bill_extra_charges(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bill_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        FOREIGN KEY (bill_id) REFERENCES bills(id) ON DELETE CASCADE)""");
      await db.execute("CREATE INDEX IF NOT EXISTS idx_bill_extra_bill_id ON bill_extra_charges(bill_id)");
    }
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
