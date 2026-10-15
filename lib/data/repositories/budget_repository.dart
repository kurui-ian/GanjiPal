import 'package:pesatrack_core/pesatrack_core.dart';
import 'package:sqflite/sqflite.dart';

import '../datasources/database_helper.dart';

class BudgetRepository {
  final DatabaseHelper _dbHelper;

  BudgetRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<BudgetModel>> getAllBudgets() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'budgets',
      orderBy: 'is_active DESC, period ASC',
    );
    return maps.map((m) => BudgetModel.fromMap(m)).toList();
  }

  Future<void> saveBudget(BudgetModel budget) async {
    final db = await _dbHelper.database;
    await db.insert(
      'budgets',
      budget.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteBudget(String id) async {
    final db = await _dbHelper.database;
    await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }
}
