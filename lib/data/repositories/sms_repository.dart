import 'package:pesatrack_core/pesatrack_core.dart';
import 'package:sqflite/sqflite.dart';

import '../datasources/database_helper.dart';

class SmsRepository {
  final DatabaseHelper _dbHelper;

  SmsRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<void> recordImport(SmsImportRecord record) async {
    final db = await _dbHelper.database;
    await db.insert(
      'sms_import_records',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<SmsImportRecord>> getRecentImports({int limit = 100}) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sms_import_records',
      orderBy: 'imported_at DESC',
      limit: limit,
    );
    return maps.map((m) => SmsImportRecord.fromMap(m)).toList();
  }

  Future<bool> hasImportedFingerprint(String fingerprint) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sms_import_records',
      where: 'message_fingerprint = ?',
      whereArgs: [fingerprint],
      limit: 1,
    );
    return maps.isNotEmpty;
  }
}
