import 'package:pesatrack_core/pesatrack_core.dart';
import 'package:sqflite/sqflite.dart';

import '../datasources/database_helper.dart';

class TransactionRepository {
  final DatabaseHelper _dbHelper;

  TransactionRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<TransactionModel>> getAllTransactions({
    int? limit,
    int? offset,
  }) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );
    return maps.map((m) => TransactionModel.fromMap(m)).toList();
  }

  Future<List<TransactionModel>> getFilteredTransactions({
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
    FinancialClassification? classification,
    TransactionType? transactionType,
    String? categoryId,
    int? minAmountCents,
    int? maxAmountCents,
    ReviewStatus? reviewStatus,
    String orderBy = 'timestamp DESC',
  }) async {
    final db = await _dbHelper.database;
    final List<String> whereClauses = [];
    final List<dynamic> whereArgs = [];

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final term = '%${searchQuery.trim().toLowerCase()}%';
      whereClauses.add(
        '(LOWER(counterparty_name) LIKE ? OR LOWER(description) LIKE ? OR LOWER(account_reference) LIKE ? OR LOWER(mpesa_reference) LIKE ?)',
      );
      whereArgs.addAll([term, term, term, term]);
    }

    if (startDate != null) {
      whereClauses.add('timestamp >= ?');
      whereArgs.add(startDate.millisecondsSinceEpoch);
    }

    if (endDate != null) {
      whereClauses.add('timestamp <= ?');
      whereArgs.add(endDate.millisecondsSinceEpoch);
    }

    if (classification != null) {
      whereClauses.add('classification = ?');
      whereArgs.add(classification.name);
    }

    if (transactionType != null) {
      whereClauses.add('transaction_type = ?');
      whereArgs.add(transactionType.name);
    }

    if (categoryId != null) {
      whereClauses.add('category_id = ?');
      whereArgs.add(categoryId);
    }

    if (minAmountCents != null) {
      whereClauses.add('amount_cents >= ?');
      whereArgs.add(minAmountCents);
    }

    if (maxAmountCents != null) {
      whereClauses.add('amount_cents <= ?');
      whereArgs.add(maxAmountCents);
    }

    if (reviewStatus != null) {
      whereClauses.add('review_status = ?');
      whereArgs.add(reviewStatus.name);
    }

    final where = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: where,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: orderBy,
    );

    return maps.map((m) => TransactionModel.fromMap(m)).toList();
  }

  Future<TransactionModel?> getTransactionByReference(String reference) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'mpesa_reference = ?',
      whereArgs: [reference],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return TransactionModel.fromMap(maps.first);
  }

  Future<TransactionModel?> getTransactionByFingerprint(
    String fingerprint,
  ) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'fingerprint = ?',
      whereArgs: [fingerprint],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return TransactionModel.fromMap(maps.first);
  }

  /// Inserts a transaction safely. Ignores duplicates if fingerprint already exists.
  /// Returns true if inserted, false if already exists (duplicate).
  Future<bool> insertTransaction(TransactionModel transaction) async {
    final db = await _dbHelper.database;
    try {
      final id = await db.insert(
        'transactions',
        transaction.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      return id > 0;
    } on DatabaseException catch (_) {
      // Fingerprint or reference collision - safely ignore duplicate
      return false;
    }
  }

  /// Batch inserts transactions within an ACID transaction.
  /// Returns count of newly inserted transactions.
  Future<int> insertBatch(List<TransactionModel> transactions) async {
    final db = await _dbHelper.database;
    int insertedCount = 0;

    await db.transaction((txn) async {
      for (final tx in transactions) {
        try {
          final id = await txn.insert(
            'transactions',
            tx.toMap(),
            conflictAlgorithm: ConflictAlgorithm.abort,
          );
          if (id > 0) insertedCount++;
        } on DatabaseException catch (_) {
          // Skip duplicates silently
        }
      }
    });

    return insertedCount;
  }

  Future<bool> updateTransaction(TransactionModel transaction) async {
    final db = await _dbHelper.database;
    final rows = await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
    return rows > 0;
  }

  Future<bool> deleteTransaction(String id) async {
    final db = await _dbHelper.database;
    final rows = await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
    return rows > 0;
  }

  Future<List<TransactionModel>> getTransactionsInDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'timestamp >= ? AND timestamp <= ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'timestamp DESC',
    );
    return maps.map((m) => TransactionModel.fromMap(m)).toList();
  }
}
