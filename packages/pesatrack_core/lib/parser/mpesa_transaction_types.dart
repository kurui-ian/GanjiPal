/// Transaction types identified in M-Pesa SMS messages and manual entries.
enum TransactionType {
  sendMoney,
  receiveMoney,
  payBill,
  buyGoods,
  withdrawAgent,
  withdrawAtm,
  deposit,
  airtime,
  fee,
  reversal,
  refund,
  transfer,
  unknown;

  String get displayName {
    switch (this) {
      case TransactionType.sendMoney:
        return 'Send Money';
      case TransactionType.receiveMoney:
        return 'Received Money';
      case TransactionType.payBill:
        return 'PayBill';
      case TransactionType.buyGoods:
        return 'Buy Goods / Till';
      case TransactionType.withdrawAgent:
        return 'Agent Withdrawal';
      case TransactionType.withdrawAtm:
        return 'ATM Withdrawal';
      case TransactionType.deposit:
        return 'Cash Deposit';
      case TransactionType.airtime:
        return 'Airtime';
      case TransactionType.fee:
        return 'Transaction Fee';
      case TransactionType.reversal:
        return 'Reversal';
      case TransactionType.refund:
        return 'Refund';
      case TransactionType.transfer:
        return 'Account Transfer';
      case TransactionType.unknown:
        return 'Unclassified';
    }
  }
}

/// Financial classification ensuring semantic correctness.
/// Distinguishes between expenses, income, internal transfers, and cash conversions.
enum FinancialClassification {
  expense,
  income,
  transfer,
  withdrawal,
  deposit,
  adjustment,
  unclassified;

  String get displayName {
    switch (this) {
      case FinancialClassification.expense:
        return 'Expense';
      case FinancialClassification.income:
        return 'Income';
      case FinancialClassification.transfer:
        return 'Transfer';
      case FinancialClassification.withdrawal:
        return 'Cash Withdrawal';
      case FinancialClassification.deposit:
        return 'Cash Deposit';
      case FinancialClassification.adjustment:
        return 'Reversal / Refund';
      case FinancialClassification.unclassified:
        return 'Needs Review';
    }
  }
}

/// Source of the transaction entry.
enum TransactionSource {
  autoSms,
  importedSms,
  manual;

  String get displayName {
    switch (this) {
      case TransactionSource.autoSms:
        return 'Auto SMS';
      case TransactionSource.importedSms:
        return 'Imported SMS';
      case TransactionSource.manual:
        return 'Manual Entry';
    }
  }
}

/// Review and classification confidence status.
enum ReviewStatus {
  verified,
  needsReview,
  flagged;

  String get displayName {
    switch (this) {
      case ReviewStatus.verified:
        return 'Verified';
      case ReviewStatus.needsReview:
        return 'Needs Review';
      case ReviewStatus.flagged:
        return 'Flagged';
    }
  }
}

/// Budget periods supported by PesaTrack.
enum BudgetPeriod {
  daily,
  weekly,
  monthly;

  String get displayName {
    switch (this) {
      case BudgetPeriod.daily:
        return 'Daily';
      case BudgetPeriod.weekly:
        return 'Weekly';
      case BudgetPeriod.monthly:
        return 'Monthly';
    }
  }
}
