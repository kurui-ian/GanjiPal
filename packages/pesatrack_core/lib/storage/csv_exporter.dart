import 'package:intl/intl.dart';
import '../models/transaction.dart';

/// Exports transaction history to standard RFC 4180 CSV format.
/// Excludes sensitive raw SMS bodies and internal database keys.
class CsvExporter {
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

  /// Generates CSV content from a list of transactions.
  static String exportTransactionsToCsv(List<TransactionModel> transactions) {
    final buffer = StringBuffer();

    // CSV Header
    buffer.writeln(
      'Reference,Date,Type,Classification,Amount (KES),Fee (KES),Total (KES),Balance (KES),Category,Counterparty,Phone,Account,Description,Source,Timestamp (ISO)',
    );

    for (final tx in transactions) {
      final dateStr = _dateFormat.format(tx.timestamp);
      final isoStr = tx.timestamp.toIso8601String();
      final ref = _sanitizeAndEscape(tx.mpesaReference ?? '');
      final type = _sanitizeAndEscape(tx.transactionType.displayName);
      final classification = _sanitizeAndEscape(tx.classification.displayName);
      final amount = (tx.amountCents / 100.0).toStringAsFixed(2);
      final fee = (tx.feeCents / 100.0).toStringAsFixed(2);
      final total = ((tx.amountCents + tx.feeCents) / 100.0).toStringAsFixed(2);
      final balance = tx.balanceAfterCents != null
          ? (tx.balanceAfterCents! / 100.0).toStringAsFixed(2)
          : '';
      final category = _sanitizeAndEscape(tx.categoryName);
      final counterparty = _sanitizeAndEscape(tx.counterpartyName ?? '');
      final phone = _sanitizeAndEscape(tx.counterpartyPhone ?? '');
      final account = _sanitizeAndEscape(tx.accountReference ?? '');
      final desc = _sanitizeAndEscape(tx.description ?? '');
      final source = _sanitizeAndEscape(tx.source.displayName);

      buffer.writeln(
        '$ref,$dateStr,$type,$classification,$amount,$fee,$total,$balance,$category,$counterparty,$phone,$account,$desc,$source,$isoStr',
      );
    }

    return buffer.toString();
  }

  /// Sanitizes against CSV formula injection and escapes RFC 4180 special characters.
  static String _sanitizeAndEscape(String val) {
    if (val.isEmpty) return '';

    var clean = val;
    // Prevent formula injection if cell begins with =, +, -, @, or tab
    if (clean.startsWith('=') ||
        clean.startsWith('+') ||
        clean.startsWith('-') ||
        clean.startsWith('@') ||
        clean.startsWith('\t')) {
      clean = "'$clean";
    }

    if (clean.contains(',') ||
        clean.contains('"') ||
        clean.contains('\n') ||
        clean.contains('\r')) {
      return '"${clean.replaceAll('"', '""')}"';
    }
    return clean;
  }
}
