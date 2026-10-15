import 'dart:convert';
import '../models/budget.dart';
import '../models/category.dart';
import '../models/transaction.dart';

/// Structured payload of a complete PesaTrack backup.
class BackupPayload {
  final int version;
  final DateTime exportedAt;
  final List<TransactionModel> transactions;
  final List<CategoryModel> categories;
  final List<BudgetModel> budgets;

  const BackupPayload({
    required this.version,
    required this.exportedAt,
    required this.transactions,
    required this.categories,
    required this.budgets,
  });
}

/// Versioned JSON backup encoder, decoder, and validator.
class BackupCodec {
  static const int currentVersion = 1;

  /// Serializes application data to a versioned JSON string.
  static String encode({
    required List<TransactionModel> transactions,
    required List<CategoryModel> categories,
    required List<BudgetModel> budgets,
  }) {
    final payload = {
      'app': 'PesaTrack',
      'version': currentVersion,
      'exported_at': DateTime.now().toIso8601String(),
      'transactions': transactions.map((t) => t.toMap()).toList(),
      'categories': categories.map((c) => c.toMap()).toList(),
      'budgets': budgets.map((b) => b.toMap()).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Decodes and rigorously validates a backup JSON string.
  static BackupPayload decode(String jsonString) {
    dynamic parsed;
    try {
      parsed = jsonDecode(jsonString);
    } catch (e) {
      throw const FormatException('Invalid JSON in backup file');
    }

    if (parsed is! Map<String, dynamic>) {
      throw const FormatException('Backup root must be a JSON object');
    }

    if (parsed['app'] != 'PesaTrack') {
      throw const FormatException(
          'Unrecognized backup file: missing PesaTrack signature');
    }

    final version = parsed['version'] as int?;
    if (version == null || version < 1 || version > currentVersion) {
      throw FormatException('Unsupported backup version: $version');
    }

    final exportedAtStr = parsed['exported_at'] as String?;
    final exportedAt =
        exportedAtStr != null ? DateTime.parse(exportedAtStr) : DateTime.now();

    // Parse transactions
    final rawTxList = parsed['transactions'] as List<dynamic>? ?? [];
    final transactions = <TransactionModel>[];
    for (final raw in rawTxList) {
      if (raw is Map<String, dynamic>) {
        transactions.add(TransactionModel.fromMap(raw));
      }
    }

    // Parse categories
    final rawCatList = parsed['categories'] as List<dynamic>? ?? [];
    final categories = <CategoryModel>[];
    for (final raw in rawCatList) {
      if (raw is Map<String, dynamic>) {
        categories.add(CategoryModel.fromMap(raw));
      }
    }

    // Parse budgets
    final rawBudgetList = parsed['budgets'] as List<dynamic>? ?? [];
    final budgets = <BudgetModel>[];
    for (final raw in rawBudgetList) {
      if (raw is Map<String, dynamic>) {
        budgets.add(BudgetModel.fromMap(raw));
      }
    }

    return BackupPayload(
      version: version,
      exportedAt: exportedAt,
      transactions: transactions,
      categories: categories,
      budgets: budgets,
    );
  }
}
