import '../models/transaction.dart';
import '../parser/mpesa_transaction_types.dart';

/// Aggregated financial summary for a reporting period.
class FinancialSummary {
  final int totalPrincipalExpensesCents;
  final int totalFeesCents;
  final int totalGrossSpendingCents;
  final int totalIncomeCents;
  final int totalTransfersSentCents;
  final int totalCashWithdrawnCents;
  final int totalCashDepositedCents;
  final int totalReversalsCents;
  final int netSpendingCents;
  final int netCashFlowCents;
  final int transactionCount;
  final int expenseTransactionCount;

  const FinancialSummary({
    required this.totalPrincipalExpensesCents,
    required this.totalFeesCents,
    required this.totalGrossSpendingCents,
    required this.totalIncomeCents,
    required this.totalTransfersSentCents,
    required this.totalCashWithdrawnCents,
    required this.totalCashDepositedCents,
    required this.totalReversalsCents,
    required this.netSpendingCents,
    required this.netCashFlowCents,
    required this.transactionCount,
    required this.expenseTransactionCount,
  });

  double get grossSpendingInShillings => totalGrossSpendingCents / 100.0;
  double get netSpendingInShillings => netSpendingCents / 100.0;
  double get incomeInShillings => totalIncomeCents / 100.0;
  double get feesInShillings => totalFeesCents / 100.0;
  double get cashWithdrawnInShillings => totalCashWithdrawnCents / 100.0;
  double get netCashFlowInShillings => netCashFlowCents / 100.0;

  static const FinancialSummary zero = FinancialSummary(
    totalPrincipalExpensesCents: 0,
    totalFeesCents: 0,
    totalGrossSpendingCents: 0,
    totalIncomeCents: 0,
    totalTransfersSentCents: 0,
    totalCashWithdrawnCents: 0,
    totalCashDepositedCents: 0,
    totalReversalsCents: 0,
    netSpendingCents: 0,
    netCashFlowCents: 0,
    transactionCount: 0,
    expenseTransactionCount: 0,
  );
}

/// Category spending aggregation entry.
class CategorySpending {
  final String categoryId;
  final String categoryName;
  final int amountCents;
  final int transactionCount;
  final double percentageOfTotal;

  const CategorySpending({
    required this.categoryId,
    required this.categoryName,
    required this.amountCents,
    required this.transactionCount,
    required this.percentageOfTotal,
  });

  double get amountInShillings => amountCents / 100.0;
}

/// Merchant spending aggregation entry.
class MerchantSpending {
  final String merchantName;
  final int totalAmountCents;
  final int transactionCount;

  const MerchantSpending({
    required this.merchantName,
    required this.totalAmountCents,
    required this.transactionCount,
  });

  double get totalInShillings => totalAmountCents / 100.0;
}

/// Core financial arithmetic and reporting engine.
class FinancialCalculator {
  /// Computes summary metrics for a given list of transactions.
  static FinancialSummary calculateSummary(
    List<TransactionModel> transactions, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    int principalExpenses = 0;
    int fees = 0;
    int income = 0;
    int transfers = 0;
    int withdrawals = 0;
    int deposits = 0;
    int reversals = 0;
    int count = 0;
    int expenseCount = 0;

    for (final tx in transactions) {
      if (startDate != null && tx.timestamp.isBefore(startDate)) continue;
      if (endDate != null && tx.timestamp.isAfter(endDate)) continue;

      count++;
      fees += tx.feeCents;

      switch (tx.classification) {
        case FinancialClassification.expense:
          principalExpenses += tx.amountCents;
          expenseCount++;
          break;
        case FinancialClassification.income:
          income += tx.amountCents;
          break;
        case FinancialClassification.transfer:
          transfers += tx.amountCents;
          break;
        case FinancialClassification.withdrawal:
          withdrawals += tx.amountCents;
          break;
        case FinancialClassification.deposit:
          deposits += tx.amountCents;
          break;
        case FinancialClassification.adjustment:
          reversals += tx.amountCents;
          break;
        case FinancialClassification.unclassified:
          // Unclassified transactions are omitted from spending until reviewed
          break;
      }
    }

    final grossSpending = principalExpenses + fees;
    final netSpending =
        grossSpending > reversals ? grossSpending - reversals : 0;

    // Net Cash Flow: (Money in) - (Money out)
    // Money In: income + deposits + reversals
    // Money Out: principalExpenses + fees + transfers + withdrawals
    final moneyIn = income + deposits + reversals;
    final moneyOut = principalExpenses + fees + transfers + withdrawals;
    final netCashFlow = moneyIn - moneyOut;

    return FinancialSummary(
      totalPrincipalExpensesCents: principalExpenses,
      totalFeesCents: fees,
      totalGrossSpendingCents: grossSpending,
      totalIncomeCents: income,
      totalTransfersSentCents: transfers,
      totalCashWithdrawnCents: withdrawals,
      totalCashDepositedCents: deposits,
      totalReversalsCents: reversals,
      netSpendingCents: netSpending,
      netCashFlowCents: netCashFlow,
      transactionCount: count,
      expenseTransactionCount: expenseCount,
    );
  }

  /// Calculates spending breakdown across expense categories.
  static List<CategorySpending> calculateCategoryBreakdown(
    List<TransactionModel> transactions, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final Map<String, int> categoryAmounts = {};
    final Map<String, String> categoryNames = {};
    final Map<String, int> categoryCounts = {};
    int totalExpenses = 0;

    for (final tx in transactions) {
      if (startDate != null && tx.timestamp.isBefore(startDate)) continue;
      if (endDate != null && tx.timestamp.isAfter(endDate)) continue;

      // Only count expense classifications and fees
      if (tx.classification == FinancialClassification.expense) {
        final catId = tx.categoryId;
        categoryAmounts[catId] = (categoryAmounts[catId] ?? 0) + tx.amountCents;
        categoryNames[catId] = tx.categoryName;
        categoryCounts[catId] = (categoryCounts[catId] ?? 0) + 1;
        totalExpenses += tx.amountCents;
      }

      // Add fee to 'fees' category if transaction fee exists
      if (tx.feeCents > 0) {
        const feeCatId = 'fees';
        categoryAmounts[feeCatId] =
            (categoryAmounts[feeCatId] ?? 0) + tx.feeCents;
        categoryNames[feeCatId] = 'Transaction Fees';
        categoryCounts[feeCatId] = (categoryCounts[feeCatId] ?? 0) + 1;
        totalExpenses += tx.feeCents;
      }
    }

    if (totalExpenses == 0) return [];

    final results = <CategorySpending>[];
    categoryAmounts.forEach((catId, cents) {
      final percentage = cents / totalExpenses;
      results.add(CategorySpending(
        categoryId: catId,
        categoryName: categoryNames[catId] ?? catId,
        amountCents: cents,
        transactionCount: categoryCounts[catId] ?? 0,
        percentageOfTotal: percentage,
      ));
    });

    // Sort highest spending first
    results.sort((a, b) => b.amountCents.compareTo(a.amountCents));
    return results;
  }

  /// Groups expenses by date (day resolution) for timeline charts.
  static Map<DateTime, int> calculateDailySpending(
    List<TransactionModel> transactions, {
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final Map<DateTime, int> dailySpending = {};

    // Initialize all dates in range with 0 cents
    var cur = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    while (!cur.isAfter(end)) {
      dailySpending[cur] = 0;
      cur = cur.add(const Duration(days: 1));
    }

    for (final tx in transactions) {
      if (tx.timestamp.isBefore(startDate) || tx.timestamp.isAfter(endDate))
        continue;

      if (tx.classification == FinancialClassification.expense) {
        final day =
            DateTime(tx.timestamp.year, tx.timestamp.month, tx.timestamp.day);
        dailySpending[day] =
            (dailySpending[day] ?? 0) + tx.amountCents + tx.feeCents;
      }
    }

    return dailySpending;
  }

  /// Finds top merchants or recipients by total spending.
  static List<MerchantSpending> findTopMerchants(
    List<TransactionModel> transactions, {
    int limit = 5,
  }) {
    final Map<String, int> amounts = {};
    final Map<String, int> counts = {};

    for (final tx in transactions) {
      if (tx.classification != FinancialClassification.expense) continue;
      final name = tx.counterpartyName?.trim();
      if (name == null || name.isEmpty) continue;

      amounts[name] = (amounts[name] ?? 0) + tx.amountCents;
      counts[name] = (counts[name] ?? 0) + 1;
    }

    final list = amounts.entries.map((e) {
      return MerchantSpending(
        merchantName: e.key,
        totalAmountCents: e.value,
        transactionCount: counts[e.key] ?? 1,
      );
    }).toList();

    list.sort((a, b) => b.totalAmountCents.compareTo(a.totalAmountCents));
    return list.take(limit).toList();
  }
}
