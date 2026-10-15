import '../models/budget.dart';
import '../models/transaction.dart';
import '../parser/mpesa_transaction_types.dart';

/// Real-time status for an individual budget.
class BudgetStatus {
  final BudgetModel budget;
  final int spentCents;
  final int limitCents;
  final int remainingCents;
  final double percentageUsed;
  final bool isOverBudget;
  final bool isWarning;
  final DateTime periodStart;
  final DateTime periodEnd;

  const BudgetStatus({
    required this.budget,
    required this.spentCents,
    required this.limitCents,
    required this.remainingCents,
    required this.percentageUsed,
    required this.isOverBudget,
    required this.isWarning,
    required this.periodStart,
    required this.periodEnd,
  });

  double get spentInShillings => spentCents / 100.0;
  double get limitInShillings => limitCents / 100.0;
  double get remainingInShillings => remainingCents / 100.0;
}

/// Calculates budget spending and threshold triggers.
class BudgetCalculator {
  /// Computes the start and end of the budget period relative to [referenceDate].
  static ({DateTime start, DateTime end}) getPeriodBounds(
    BudgetPeriod period,
    DateTime referenceDate,
  ) {
    switch (period) {
      case BudgetPeriod.daily:
        final start = DateTime(
            referenceDate.year, referenceDate.month, referenceDate.day);
        final end = DateTime(referenceDate.year, referenceDate.month,
            referenceDate.day, 23, 59, 59, 999);
        return (start: start, end: end);

      case BudgetPeriod.weekly:
        // Week starting Monday
        final weekday = referenceDate.weekday; // 1 is Monday
        final monday = referenceDate.subtract(Duration(days: weekday - 1));
        final start = DateTime(monday.year, monday.month, monday.day);
        final sunday = start.add(const Duration(
            days: 6, hours: 23, minutes: 59, seconds: 59, milliseconds: 999));
        return (start: start, end: sunday);

      case BudgetPeriod.monthly:
        final start = DateTime(referenceDate.year, referenceDate.month, 1);
        final nextMonth = referenceDate.month == 12
            ? DateTime(referenceDate.year + 1, 1, 1)
            : DateTime(referenceDate.year, referenceDate.month + 1, 1);
        final end = nextMonth.subtract(const Duration(milliseconds: 1));
        return (start: start, end: end);
    }
  }

  /// Evaluates spending against a configured budget.
  static BudgetStatus evaluateBudget(
    BudgetModel budget,
    List<TransactionModel> transactions, {
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final bounds = getPeriodBounds(budget.period, now);

    int totalSpent = 0;

    for (final tx in transactions) {
      if (tx.timestamp.isBefore(bounds.start) ||
          tx.timestamp.isAfter(bounds.end)) {
        continue;
      }

      // Check category filter if budget is category-specific
      if (budget.categoryId != null && tx.categoryId != budget.categoryId) {
        continue;
      }

      // Only count expense transactions and their fees
      if (tx.classification == FinancialClassification.expense) {
        totalSpent += tx.amountCents + tx.feeCents;
      }
    }

    final remaining = budget.limitCents - totalSpent;
    final percentage =
        budget.limitCents > 0 ? (totalSpent / budget.limitCents) : 0.0;
    final isOver = totalSpent >= budget.limitCents;
    final isWarn = !isOver && (percentage >= budget.warningThresholdPercent);

    return BudgetStatus(
      budget: budget,
      spentCents: totalSpent,
      limitCents: budget.limitCents,
      remainingCents: remaining > 0 ? remaining : 0,
      percentageUsed: percentage,
      isOverBudget: isOver,
      isWarning: isWarn,
      periodStart: bounds.start,
      periodEnd: bounds.end,
    );
  }
}
