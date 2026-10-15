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
      'Reference,Date,Type,Classification,Amount (KES),Fee (KES),Total (KES),Category,Counterparty,Phone,Account,Description,Source',
    );

    for (final tx in transactions) {
      final dateStr = _dateFormat.format(tx.timestamp);
      final ref = _escape(tx.mpesaReference ?? '');
      final type = _escape(tx.transactionType.displayName);
      final classification = _escape(tx.classification.displayName);
      final amount = (tx.amountCents / 100.0).toStringAsFixed(2);
      final fee = (tx.feeCents / 100.0).toStringAsFixed(2);
      final total = ((tx.amountCents + tx.feeCents) / 100.0).toStringAsFixed(2);
      final category = _escape(tx.categoryName);
      final counterparty = _escape(tx.counterpartyName ?? '');
      final phone = _escape(tx.counterpartyPhone ?? '');
      final account = _escape(tx.accountReference ?? '');
      final desc = _escape(tx.description ?? '');
      final source = _escape(tx.source.displayName);

      buffer.writeln(
        '$ref,$dateStr,$type,$classification,$amount,$fee,$total,$category,$counterparty,$phone,$account,$desc,$source',
      );
    }

    return buffer.toString();
  }

  static String _escape(String val) {
    if (val.contains(',') ||
        val.contains('"') ||
        val.contains('\n') ||
        val.contains('\r')) {
      return '"${val.replaceAll('"', '""')}"';
    }
    return val;
  }
}
