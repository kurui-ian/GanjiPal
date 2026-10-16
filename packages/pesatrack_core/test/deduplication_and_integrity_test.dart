import 'package:pesatrack_core/pesatrack_core.dart';
import 'package:test/test.dart';

void main() {
  group('Deduplication & Data Integrity Tests', () {
    final now = DateTime(2026, 10, 15, 16, 30);

    test('Generates deterministic fingerprint for identical M-Pesa reference',
        () {
      final fp1 = DeduplicationService.generateFingerprint(
        mpesaReference: 'QA12BC34DE',
        amountCents: 150000,
        timestamp: now,
      );

      final fp2 = DeduplicationService.generateFingerprint(
        mpesaReference: 'qa12bc34de', // case-insensitive check
        amountCents: 150000,
        timestamp: now,
      );

      expect(fp1, equals(fp2));
      expect(fp1, isNotEmpty);
    });

    test(
        'Differentiates transactions with identical amount and timestamp but different recipients',
        () {
      final fpAlice = DeduplicationService.generateFingerprint(
        amountCents: 100000,
        timestamp: now,
        counterparty: 'Alice M',
        type: TransactionType.sendMoney,
      );

      final fpBob = DeduplicationService.generateFingerprint(
        amountCents: 100000,
        timestamp: now,
        counterparty: 'Bob K',
        type: TransactionType.sendMoney,
      );

      expect(fpAlice, isNot(equals(fpBob)));
    });

    test('CsvExporter serializes transactions into valid CSV with headers', () {
      final tx = TransactionModel(
        id: '1',
        mpesaReference: 'QA12BC34DE',
        transactionType: TransactionType.buyGoods,
        classification: FinancialClassification.expense,
        amountCents: 150000,
        feeCents: 0,
        timestamp: now,
        counterpartyName: 'Naivas, Westlands',
        categoryId: 'food_groceries',
        categoryName: 'Food & Groceries',
        source: TransactionSource.autoSms,
        fingerprint: 'fp1',
        createdAt: now,
        updatedAt: now,
      );

      final csv = CsvExporter.exportTransactionsToCsv([tx]);

      expect(csv, contains('Reference,Date,Type,Classification,Amount (KES)'));
      expect(csv, contains('Timestamp (ISO)'));
      expect(csv, contains('QA12BC34DE'));
      expect(
          csv, contains('"Naivas, Westlands"')); // Escaped quotes due to comma
      expect(csv, contains('1500.00'));
      expect(csv, contains(now.toIso8601String()));
    });

    test('CsvExporter sanitizes against CSV formula injection', () {
      final maliciousTx = TransactionModel(
        id: '2',
        mpesaReference: 'SH01MAL01',
        transactionType: TransactionType.buyGoods,
        classification: FinancialClassification.expense,
        amountCents: 10000,
        feeCents: 0,
        timestamp: now,
        counterpartyName: '=CMD|calc.exe',
        accountReference: '+44201234',
        categoryId: 'other',
        categoryName: 'Other / General',
        source: TransactionSource.manual,
        fingerprint: 'fp2',
        createdAt: now,
        updatedAt: now,
      );

      final csv = CsvExporter.exportTransactionsToCsv([maliciousTx]);

      // Ensure formulas starting with = or + are escaped with single-quote prefix
      expect(csv, contains("'=CMD|calc.exe"));
      expect(csv, contains("'+44201234"));
    });

    test('BackupCodec encodes and decodes complete data roundtrip', () {
      final tx = TransactionModel(
        id: '1',
        mpesaReference: 'QA12BC34DE',
        transactionType: TransactionType.sendMoney,
        classification: FinancialClassification.transfer,
        amountCents: 200000,
        feeCents: 1500,
        timestamp: now,
        counterpartyName: 'Jane Doe',
        categoryId: 'transfers',
        categoryName: 'Transfers',
        source: TransactionSource.autoSms,
        fingerprint: 'fp1',
        createdAt: now,
        updatedAt: now,
      );

      final category = const CategoryModel(
        id: 'custom_cat',
        name: 'Custom Category',
        iconName: 'star',
        colorValue: 0xFFFF0000,
      );

      final budget = BudgetModel(
        id: 'b1',
        period: BudgetPeriod.monthly,
        limitCents: 5000000,
        startDate: now,
        createdAt: now,
        updatedAt: now,
      );

      final jsonBackup = BackupCodec.encode(
        transactions: [tx],
        categories: [category],
        budgets: [budget],
      );

      expect(jsonBackup, contains('"app": "PesaTrack"'));
      expect(jsonBackup, contains('"version": 1'));

      final restored = BackupCodec.decode(jsonBackup);

      expect(restored.version, equals(1));
      expect(restored.transactions.length, equals(1));
      expect(restored.transactions.first.mpesaReference, equals('QA12BC34DE'));
      expect(restored.transactions.first.amountCents, equals(200000));
      expect(restored.categories.length, equals(1));
      expect(restored.categories.first.id, equals('custom_cat'));
      expect(restored.budgets.length, equals(1));
      expect(restored.budgets.first.limitCents, equals(5000000));
    });

    test('BackupCodec rejects corrupted or foreign JSON structures', () {
      expect(() => BackupCodec.decode('{ not json }'),
          throwsA(isA<FormatException>()));
      expect(() => BackupCodec.decode('{"app": "OtherApp", "version": 1}'),
          throwsA(isA<FormatException>()));
      expect(() => BackupCodec.decode('{"app": "PesaTrack", "version": 999}'),
          throwsA(isA<FormatException>()));
    });
  });
}
