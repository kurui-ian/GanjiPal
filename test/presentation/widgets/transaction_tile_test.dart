import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pesatrack/presentation/widgets/transaction_tile.dart';
import 'package:pesatrack_core/pesatrack_core.dart';

void main() {
  group('TransactionTile Widget Tests', () {
    final testDate = DateTime(2026, 10, 16, 14, 30);

    testWidgets('renders expense transaction with correct formatting and negative sign', (
      tester,
    ) async {
      final expenseTx = TransactionModel(
        id: 'tx_expense_1',
        mpesaReference: 'SH01EX001',
        transactionType: TransactionType.buyGoods,
        classification: FinancialClassification.expense,
        amountCents: 245000, // 2,450.00 KSh
        feeCents: 0,
        currency: 'KES',
        timestamp: testDate,
        counterpartyName: 'NAIVAS SUPERMARKET',
        accountReference: '654321',
        categoryId: 'food_groceries',
        categoryName: 'Food & Groceries',
        source: TransactionSource.importedSms,
        fingerprint: 'fp_expense_1',
        createdAt: testDate,
        updatedAt: testDate,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionTile(transaction: expenseTx),
          ),
        ),
      );

      expect(find.text('NAIVAS SUPERMARKET'), findsOneWidget);
      expect(find.text('- KSh 2,450.00'), findsOneWidget);
      expect(find.text('Buy Goods / Till'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);
      expect(find.textContaining('Fee:'), findsNothing);
      expect(find.text('Review'), findsNothing);
    });

    testWidgets('renders income transaction with positive sign and downward arrow', (
      tester,
    ) async {
      final incomeTx = TransactionModel(
        id: 'tx_income_1',
        mpesaReference: 'SH02IN002',
        transactionType: TransactionType.receiveMoney,
        classification: FinancialClassification.income,
        amountCents: 1500000, // 15,000.00 KSh
        feeCents: 0,
        currency: 'KES',
        timestamp: testDate,
        counterpartyName: 'ALICE WANJIRU',
        counterpartyPhone: '0712345678',
        categoryId: 'income',
        categoryName: 'Income & Earnings',
        source: TransactionSource.importedSms,
        fingerprint: 'fp_income_1',
        createdAt: testDate,
        updatedAt: testDate,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionTile(transaction: incomeTx),
          ),
        ),
      );

      expect(find.text('ALICE WANJIRU'), findsOneWidget);
      expect(find.text('+ KSh 15,000.00'), findsOneWidget);
      expect(find.text('Received Money'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_downward_rounded), findsOneWidget);
    });

    testWidgets('displays transaction fee when feeCents is greater than zero', (
      tester,
    ) async {
      final feeTx = TransactionModel(
        id: 'tx_paybill_fee',
        mpesaReference: 'SH03PB003',
        transactionType: TransactionType.payBill,
        classification: FinancialClassification.expense,
        amountCents: 500000, // 5,000.00 KSh
        feeCents: 2300, // 23.00 KSh
        currency: 'KES',
        timestamp: testDate,
        counterpartyName: 'KPLC PREPAID',
        accountReference: '123456789',
        categoryId: 'utilities',
        categoryName: 'Utilities & Bills',
        source: TransactionSource.importedSms,
        fingerprint: 'fp_paybill_1',
        createdAt: testDate,
        updatedAt: testDate,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionTile(transaction: feeTx),
          ),
        ),
      );

      expect(find.text('KPLC PREPAID'), findsOneWidget);
      expect(find.text('- KSh 5,000.00'), findsOneWidget);
      expect(find.text('Fee: KSh 23.00'), findsOneWidget);
    });

    testWidgets('displays Review badge and triggers onTap callback', (tester) async {
      bool tapped = false;

      final reviewTx = TransactionModel(
        id: 'tx_needs_review',
        mpesaReference: 'SH04REV004',
        transactionType: TransactionType.unknown,
        classification: FinancialClassification.unclassified,
        amountCents: 35000,
        feeCents: 0,
        currency: 'KES',
        timestamp: testDate,
        counterpartyName: 'UNKNOWN MERCHANT',
        categoryId: 'other',
        categoryName: 'Other / General',
        source: TransactionSource.manual,
        fingerprint: 'fp_review_1',
        reviewStatus: ReviewStatus.needsReview,
        createdAt: testDate,
        updatedAt: testDate,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionTile(
              transaction: reviewTx,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Review'), findsOneWidget);
      expect(find.text('UNKNOWN MERCHANT'), findsOneWidget);

      await tester.tap(find.byType(TransactionTile));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
