import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:pesatrack_core/pesatrack_core.dart';
import 'package:sqflite/sqflite.dart';

/// SQLite Database Manager for PesaTrack.
/// Provides offline-first local persistence, indexes, constraints,
/// transactional inserts, and schema migrations.
class DatabaseHelper {
  static const String _databaseName = 'pesatrack.db';
  static const int _databaseVersion = 1;

  static final DatabaseHelper instance = DatabaseHelper._internal();
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Transactions Table
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        mpesa_reference TEXT,
        transaction_type TEXT NOT NULL,
        classification TEXT NOT NULL,
        amount_cents INTEGER NOT NULL,
        fee_cents INTEGER NOT NULL DEFAULT 0,
        currency TEXT NOT NULL DEFAULT 'KES',
        timestamp INTEGER NOT NULL,
        sms_received_timestamp INTEGER,
        counterparty_name TEXT,
        counterparty_phone TEXT,
        account_reference TEXT,
        description TEXT,
        category_id TEXT NOT NULL,
        category_name TEXT NOT NULL,
        source TEXT NOT NULL,
        fingerprint TEXT NOT NULL UNIQUE,
        review_status TEXT NOT NULL,
        reversal_reference TEXT,
        balance_after_cents INTEGER,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Create Indexes for high-performance dashboard queries and duplicate checks
    await db.execute(
      'CREATE INDEX idx_tx_timestamp ON transactions(timestamp)',
    );
    await db.execute(
      'CREATE INDEX idx_tx_category ON transactions(category_id)',
    );
    await db.execute(
      'CREATE INDEX idx_tx_classification ON transactions(classification)',
    );
    await db.execute(
      'CREATE INDEX idx_tx_reference ON transactions(mpesa_reference)',
    );
    await db.execute(
      'CREATE INDEX idx_tx_fingerprint ON transactions(fingerprint)',
    );

    // 2. Categories Table
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon_name TEXT NOT NULL,
        color_value INTEGER NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0,
        is_income INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // 3. Budgets Table
    await db.execute('''
      CREATE TABLE budgets (
        id TEXT PRIMARY KEY,
        category_id TEXT,
        category_name TEXT,
        period TEXT NOT NULL,
        limit_cents INTEGER NOT NULL,
        warning_threshold_percent REAL NOT NULL DEFAULT 0.80,
        start_date INTEGER NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // 4. SMS Import Audit Log Table
    await db.execute('''
      CREATE TABLE sms_import_records (
        id TEXT PRIMARY KEY,
        message_fingerprint TEXT NOT NULL,
        mpesa_reference TEXT,
        status TEXT NOT NULL,
        error_message TEXT,
        imported_at INTEGER NOT NULL,
        transaction_id TEXT
      )
    ''');

    // 5. Merchant-to-Category user mapping rules
    await db.execute('''
      CREATE TABLE merchant_category_rules (
        merchant_pattern TEXT PRIMARY KEY,
        category_id TEXT NOT NULL
      )
    ''');

    // 6. User Preferences (Settings, User Name, Avatar, etc.)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_preferences (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Seed default categories
    await _seedDefaultCategories(db);
  }

  Future<void> _seedDefaultCategories(Database db) async {
    final batch = db.batch();
    for (final cat in CategoryModel.defaults) {
      batch.insert(
        'categories',
        cat.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migration paths can be safely added here as database version increases
  }

  /// Sets a persistent string preference.
  Future<void> setPreference(String key, String value) async {
    final db = await database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_preferences (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    await db.insert(
      'user_preferences',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieves a persistent string preference.
  Future<String?> getPreference(String key) async {
    final db = await database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_preferences (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    final maps = await db.query(
      'user_preferences',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return maps.first['value'] as String?;
    }
    return null;
  }

  /// Closes database connection.
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  /// Clears all transactions, budgets, and import logs (for Settings -> Reset Data).
  /// Preserves categories.
  Future<void> clearAllUserData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('transactions');
      await txn.delete('budgets');
      await txn.delete('sms_import_records');
      await txn.delete('merchant_category_rules');
    });
  }
}
