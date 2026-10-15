import 'package:pesatrack_core/pesatrack_core.dart';
import 'package:test/test.dart';

void main() {
  group('BudgetCalculator Tests', () {
    final now = DateTime(2026, 10, 15, 14, 0);

    final transactions = [
      // Grocery expense 1: 4,000 KSh
      TransactionModel(
        id: '1',
        transactionType: TransactionType.buyGoods,
        classification: FinancialClassification.expense,
        amountCents: 400000,
        feeCents: 0,
        timestamp: now,
        categoryId: 'food_groceries',
        categoryName: 'Food & Groceries',
        source: TransactionSource.manual,
        fingerprint: 'fp1',
        createdAt: now,
        updatedAt: now,
      ),
      // Grocery expense 2: 4,500 KSh
      TransactionModel(
        id: '2',
        transactionType: TransactionType.buyGoods,
        classification: FinancialClassification.expense,
        amountCents: 450000,
        feeCents: 0,
        timestamp: now.subtract(const Duration(hours: 3)),
        categoryId: 'food_groceries',
        categoryName: 'Food & Groceries',
        source: TransactionSource.manual,
        fingerprint: 'fp2',
        createdAt: now,
        updatedAt: now,
      ),
      // Transport expense: 1,500 KSh
      TransactionModel(
        id: '3',
        transactionType: TransactionType.buyGoods,
        classification: FinancialClassification.expense,
        amountCents: 150000,
        feeCents: 0,
        timestamp: now.subtract(const Duration(hours: 1)),
        categoryId: 'transport',
        categoryName: 'Transport',
        source: TransactionSource.manual,
        fingerprint: 'fp3',
        createdAt: now,
        updatedAt: now,
      ),
    ];

    test('Computes overall daily budget status and remaining amount', () {
      final budget = BudgetModel(
        id: 'b1',
        period: BudgetPeriod.daily,
        limitCents: 1500000, // 15,000 KSh limit
        warningThresholdPercent: 0.80,
        startDate: now,
        createdAt: now,
        updatedAt: now,
      );

      final status = BudgetCalculator.evaluateBudget(budget, transactions,
          referenceDate: now);

      // Total spent today: 4,000 + 4,500 + 1,500 = 10,000 KSh (1,000,000 cents)
      expect(status.spentCents, equals(1000000));
      expect(status.remainingCents, equals(500000)); // 5,000 KSh remaining
      expect(status.percentageUsed, closeTo(10000 / 15000, 0.001));
      expect(status.isOverBudget, isFalse);
      expect(status.isWarning, isFalse); // 66.6% < 80%
    });

    test(
        'Triggers warning threshold when spending crosses configured percentage',
        () {
      final budget = BudgetModel(
        id: 'b2',
        period: BudgetPeriod.daily,
        limitCents: 1200000, // 12,000 KSh limit
        warningThresholdPercent: 0.80, // Warning at 9,600 KSh
        startDate: now,
        createdAt: now,
        updatedAt: now,
      );

      final status = BudgetCalculator.evaluateBudget(budget, transactions,
          referenceDate: now);

      // Total spent today: 10,000 KSh >= 9,600 KSh
      expect(status.isWarning, isTrue);
      expect(status.isOverBudget, isFalse);
    });

    test('Triggers over-budget status when spending exceeds limit', () {
      final budget = BudgetModel(
        id: 'b3',
        period: BudgetPeriod.daily,
        limitCents: 800000, // 8,000 KSh limit
        startDate: now,
        createdAt: now,
        updatedAt: now,
      );

      final status = BudgetCalculator.evaluateBudget(budget, transactions,
          referenceDate: now);

      expect(status.isOverBudget, isTrue);
      expect(status.remainingCents, equals(0));
    });

    test('Evaluates category-specific budget without counting other categories',
        () {
      final foodBudget = BudgetModel(
        id: 'b4',
        categoryId: 'food_groceries',
        categoryName: 'Food & Groceries',
        period: BudgetPeriod.daily,
        limitCents: 1000000, // 10,000 KSh limit for Food
        startDate: now,
        createdAt: now,
        updatedAt: now,
      );

      final status = BudgetCalculator.evaluateBudget(foodBudget, transactions,
          referenceDate: now);

      // Spent in food: 4,000 + 4,500 = 8,500 KSh (transport 1,500 is ignored)
      expect(status.spentCents, equals(850000));
      expect(status.remainingCents, equals(150000));
      expect(status.isOverBudget, isFalse);
    });
  });
}
