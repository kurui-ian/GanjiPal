import 'package:pesatrack_core/pesatrack_core.dart';
import 'package:test/test.dart';

void main() {
  group('TransactionModel Unit Tests', () {
    final now = DateTime(2026, 10, 20, 14, 30);

    final sampleTx = TransactionModel(
      id: 'tx_001',
      mpesaReference: 'QA12345678',
      transactionType: TransactionType.payBill,
      classification: FinancialClassification.expense,
      amountCents: 250000, // 2500 KES
      feeCents: 2300, // 23 KES
      currency: 'KES',
      timestamp: now,
      counterpartyName: 'KPLC PREPAID',
      counterpartyPhone: null,
      accountReference: '14234567890',
      description: 'Token purchase',
      categoryId: 'cat_utilities',
      categoryName: 'Bills & Utilities',
      source: TransactionSource.autoSms,
      fingerprint: 'fp_abc123',
      reviewStatus: ReviewStatus.verified,
      balanceAfterCents: 1540000, // 15400 KES
      createdAt: now,
      updatedAt: now,
    );

    test('correctly converts minor units (cents) to Shillings', () {
      expect(sampleTx.amountInShillings, equals(2500.0));
      expect(sampleTx.feeInShillings, equals(23.0));
      expect(sampleTx.totalOutgoingInShillings, equals(2523.0));
    });

    test('serializes to Map and deserializes from Map cleanly', () {
      final map = sampleTx.toMap();
      expect(map['id'], equals('tx_001'));
      expect(map['mpesa_reference'], equals('QA12345678'));
      expect(map['amount_cents'], equals(250000));
      expect(map['fee_cents'], equals(2300));
      expect(map['counterparty_name'], equals('KPLC PREPAID'));

      final restored = TransactionModel.fromMap(map);
      expect(restored.id, equals(sampleTx.id));
      expect(restored.mpesaReference, equals(sampleTx.mpesaReference));
      expect(restored.amountCents, equals(sampleTx.amountCents));
      expect(restored.feeCents, equals(sampleTx.feeCents));
      expect(restored.classification, equals(sampleTx.classification));
      expect(restored.transactionType, equals(sampleTx.transactionType));
      expect(restored.amountInShillings, equals(sampleTx.amountInShillings));
    });

    test('copyWith updates specified fields while retaining others', () {
      final updated = sampleTx.copyWith(
        amountCents: 300000,
        categoryName: 'Energy',
        reviewStatus: ReviewStatus.needsReview,
      );

      expect(updated.id, equals(sampleTx.id));
      expect(updated.amountCents, equals(300000));
      expect(updated.amountInShillings, equals(3000.0));
      expect(updated.categoryName, equals('Energy'));
      expect(updated.reviewStatus, equals(ReviewStatus.needsReview));
      expect(updated.mpesaReference, equals(sampleTx.mpesaReference));
    });

    test('totalOutgoingInShillings handles zero fee correctly', () {
      final noFeeTx = sampleTx.copyWith(feeCents: 0);
      expect(noFeeTx.feeInShillings, equals(0.0));
      expect(noFeeTx.totalOutgoingInShillings, equals(noFeeTx.amountInShillings));
    });
  });
}
