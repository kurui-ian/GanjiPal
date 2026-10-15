import 'package:pesatrack_core/pesatrack_core.dart';
import 'package:test/test.dart';

void main() {
  group('FinancialCalculator Tests', () {
    final now = DateTime(2026, 10, 15, 12, 0);

    final sampleTransactions = [
      // Expense 1: Supermarket 1,500 KSh (no fee)
      TransactionModel(
        id: '1',
        mpesaReference: 'REF1',
        transactionType: TransactionType.buyGoods,
        classification: FinancialClassification.expense,
        amountCents: 150000,
        feeCents: 0,
        timestamp: now,
        counterpartyName: 'Naivas Supermarket',
        categoryId: 'food_groceries',
        categoryName: 'Food & Groceries',
        source: TransactionSource.autoSms,
        fingerprint: 'fp1',
        createdAt: now,
        updatedAt: now,
      ),
      // Expense 2: Electricity 3,200 KSh + 50 KSh fee
      TransactionModel(
        id: '2',
        mpesaReference: 'REF2',
        transactionType: TransactionType.payBill,
        classification: FinancialClassification.expense,
        amountCents: 320000,
        feeCents: 5000,
        timestamp: now.subtract(const Duration(hours: 2)),
        counterpartyName: 'KPLC',
        categoryId: 'utilities',
        categoryName: 'Utilities & Bills',
        source: TransactionSource.autoSms,
        fingerprint: 'fp2',
        createdAt: now,
        updatedAt: now,
      ),
      // Income 1: Salary / Payment received 20,000 KSh
      TransactionModel(
        id: '3',
        mpesaReference: 'REF3',
        transactionType: TransactionType.receiveMoney,
        classification: FinancialClassification.income,
        amountCents: 2000000,
        feeCents: 0,
        timestamp: now.subtract(const Duration(hours: 4)),
        counterpartyName: 'Employer Ltd',
        categoryId: 'income',
        categoryName: 'Income & Earnings',
        source: TransactionSource.autoSms,
        fingerprint: 'fp3',
        createdAt: now,
        updatedAt: now,
      ),
      // Transfer 1: Sent 5,000 KSh + 15 KSh fee
      TransactionModel(
        id: '4',
        mpesaReference: 'REF4',
        transactionType: TransactionType.sendMoney,
        classification: FinancialClassification.transfer,
        amountCents: 500000,
        feeCents: 1500,
        timestamp: now.subtract(const Duration(hours: 6)),
        counterpartyName: 'John Doe',
        categoryId: 'transfers',
        categoryName: 'Transfers & Send Money',
        source: TransactionSource.autoSms,
        fingerprint: 'fp4',
        createdAt: now,
        updatedAt: now,
      ),
      // Cash Withdrawal 1: 10,000 KSh + 120 KSh fee
      TransactionModel(
        id: '5',
        mpesaReference: 'REF5',
        transactionType: TransactionType.withdrawAgent,
        classification: FinancialClassification.withdrawal,
        amountCents: 1000000,
        feeCents: 12000,
        timestamp: now.subtract(const Duration(hours: 8)),
        counterpartyName: 'Agent Nairobi',
        categoryId: 'cash_withdrawals',
        categoryName: 'Cash Withdrawals',
        source: TransactionSource.autoSms,
        fingerprint: 'fp5',
        createdAt: now,
        updatedAt: now,
      ),
      // Reversal 1: 1,500 KSh credited back
      TransactionModel(
        id: '6',
        mpesaReference: 'REF6',
        transactionType: TransactionType.reversal,
        classification: FinancialClassification.adjustment,
        amountCents: 150000,
        feeCents: 0,
        timestamp: now.subtract(const Duration(hours: 1)),
        reversalReference: 'REF1',
        categoryId: 'other',
        categoryName: 'Other / General',
        source: TransactionSource.autoSms,
        fingerprint: 'fp6',
        createdAt: now,
        updatedAt: now,
      ),
    ];

    test('Computes financial summary correctly maintaining strict semantics',
        () {
      final summary = FinancialCalculator.calculateSummary(sampleTransactions);

      // Principal expenses: 1,500 (buyGoods) + 3,200 (payBill) = 4,700 KSh (470,000 cents)
      expect(summary.totalPrincipalExpensesCents, equals(470000));

      // Fees: 0 + 50 + 0 + 15 + 120 + 0 = 185 KSh (18,500 cents)
      expect(summary.totalFeesCents, equals(18500));

      // Total gross spending: principal expenses + fees = 4,700 + 185 = 4,885 KSh (488,500 cents)
      expect(summary.totalGrossSpendingCents, equals(488500));

      // Reversals: 1,500 KSh (150,000 cents)
      expect(summary.totalReversalsCents, equals(150000));

      // Net spending: gross (4,885) - reversals (1,500) = 3,385 KSh (338,500 cents)
      expect(summary.netSpendingCents, equals(338500));
      expect(summary.netSpendingInShillings, equals(3385.00));

      // Income: 20,000 KSh (2,000,000 cents)
      expect(summary.totalIncomeCents, equals(2000000));

      // Cash withdrawn: 10,000 KSh (1,000,000 cents)
      expect(summary.totalCashWithdrawnCents, equals(1000000));

      // Transfers: 5,000 KSh (500,000 cents)
      expect(summary.totalTransfersSentCents, equals(500000));

      // Net Cash Flow:
      // Money In: income (20,000) + reversals (1,500) = 21,500 KSh
      // Money Out: principalExpenses (4,700) + fees (185) + transfers (5,000) + withdrawals (10,000) = 19,885 KSh
      // Net Cash Flow = 21,500 - 19,885 = +1,615 KSh (161,500 cents)
      expect(summary.netCashFlowCents, equals(161500));
      expect(summary.netCashFlowInShillings, equals(1615.00));
    });

    test('Does not treat money received as negative spending', () {
      final summary = FinancialCalculator.calculateSummary(sampleTransactions);
      expect(summary.totalGrossSpendingCents, isPositive);
      expect(summary.totalIncomeCents, equals(2000000));
    });

    test('Computes category breakdown accurately', () {
      final breakdown =
          FinancialCalculator.calculateCategoryBreakdown(sampleTransactions);

      expect(breakdown, isNotEmpty);
      // Top category by spending should be utilities (3,200) followed by food_groceries (1,500) and fees (185)
      expect(breakdown.first.categoryId, equals('utilities'));
      expect(breakdown.first.amountCents, equals(320000));

      final food =
          breakdown.firstWhere((c) => c.categoryId == 'food_groceries');
      expect(food.amountCents, equals(150000));

      final fees = breakdown.firstWhere((c) => c.categoryId == 'fees');
      expect(fees.amountCents, equals(18500));
    });

    test('Finds top merchants accurately', () {
      final topMerchants =
          FinancialCalculator.findTopMerchants(sampleTransactions);

      expect(topMerchants, isNotEmpty);
      expect(topMerchants.first.merchantName, equals('KPLC'));
      expect(topMerchants.first.totalAmountCents, equals(320000));
    });

    test('Filters accurately by historical date range', () {
      final startDate = now.subtract(const Duration(hours: 3));
      final endDate = now;

      final summary = FinancialCalculator.calculateSummary(
        sampleTransactions,
        startDate: startDate,
        endDate: endDate,
      );

      // Only tx 1 (now), tx 2 (now - 2h), tx 6 (now - 1h) fall within range
      expect(summary.transactionCount, equals(3));
      expect(summary.totalPrincipalExpensesCents, equals(470000));
    });
  });
}
