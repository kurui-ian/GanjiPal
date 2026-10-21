import 'package:pesatrack_core/pesatrack_core.dart';
import 'package:test/test.dart';

void main() {
  group('CsvExporter Unit Tests', () {
    final now = DateTime(2026, 10, 20, 10, 15);

    test('generates valid RFC 4180 CSV with header and transaction rows', () {
      final tx = TransactionModel(
        id: 'tx_csv_1',
        mpesaReference: 'QBW1234567',
        transactionType: TransactionType.sendMoney,
        classification: FinancialClassification.transfer,
        amountCents: 150000,
        feeCents: 1500,
        currency: 'KES',
        timestamp: now,
        counterpartyName: 'John Doe',
        counterpartyPhone: '0712345678',
        accountReference: null,
        description: 'Lunch transfer',
        categoryId: 'food_groceries',
        categoryName: 'Food & Groceries',
        source: TransactionSource.autoSms,
        fingerprint: 'fp_csv_1',
        reviewStatus: ReviewStatus.verified,
        balanceAfterCents: 850000,
        createdAt: now,
        updatedAt: now,
      );

      final csv = CsvExporter.exportTransactionsToCsv([tx]);

      expect(csv, contains('Reference,Date,Type,Classification,Amount (KES)'));
      expect(csv, contains('QBW1234567'));
      expect(csv, contains('1500.00'));
      expect(csv, contains('15.00'));
      expect(csv, contains('1515.00'));
      expect(csv, contains('8500.00'));
      expect(csv, contains('John Doe'));
    });

    test('protects against CSV spreadsheet formula injection', () {
      final maliciousTx = TransactionModel(
        id: 'tx_malicious',
        mpesaReference: 'QBW9999999',
        transactionType: TransactionType.payBill,
        classification: FinancialClassification.expense,
        amountCents: 50000,
        feeCents: 0,
        currency: 'KES',
        timestamp: now,
        counterpartyName: '=cmd|/c calc!A0', // Potential spreadsheet formula injection
        categoryId: 'general',
        categoryName: 'General',
        source: TransactionSource.manual,
        fingerprint: 'fp_malicious',
        createdAt: now,
        updatedAt: now,
      );

      final csv = CsvExporter.exportTransactionsToCsv([maliciousTx]);

      // Verifies prefixing with single quote to prevent formula execution
      expect(csv, contains("'=cmd|/c calc!A0"));
    });
  });
}
