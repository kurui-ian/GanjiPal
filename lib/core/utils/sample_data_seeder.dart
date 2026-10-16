import 'package:pesatrack_core/pesatrack_core.dart';

import '../../data/repositories/transaction_repository.dart';

/// Utility to generate and insert realistic M-Pesa sample transactions
/// for offline demos, manual QA, and local testing.
class SampleDataSeeder {
  /// Generates a curated list of realistic Kenyan M-Pesa transactions.
  static List<TransactionModel> getSampleTransactions() {
    final now = DateTime.now();
    final transactions = <TransactionModel>[];

    void addTx({
      required String ref,
      required TransactionType type,
      required FinancialClassification classification,
      required int amountCents,
      int feeCents = 0,
      required int daysAgo,
      required int hour,
      required int minute,
      String? counterpartyName,
      String? counterpartyPhone,
      String? accountRef,
      required String categoryId,
      required String categoryName,
      String? description,
      int? balanceAfterCents,
    }) {
      final time = DateTime(
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      ).subtract(Duration(days: daysAgo));

      final fingerprint = DeduplicationService.generateFingerprint(
        mpesaReference: ref,
        amountCents: amountCents,
        timestamp: time,
        counterparty: counterpartyName,
        type: type,
        accountReference: accountRef,
      );

      transactions.add(
        TransactionModel(
          id: 'sample_$ref',
          mpesaReference: ref,
          transactionType: type,
          classification: classification,
          amountCents: amountCents,
          feeCents: feeCents,
          currency: 'KES',
          timestamp: time,
          counterpartyName: counterpartyName,
          counterpartyPhone: counterpartyPhone,
          accountReference: accountRef,
          description: description,
          categoryId: categoryId,
          categoryName: categoryName,
          source: TransactionSource.manual,
          fingerprint: fingerprint,
          reviewStatus: ReviewStatus.verified,
          balanceAfterCents: balanceAfterCents,
          createdAt: time,
          updatedAt: time,
        ),
      );
    }

    // 1. Client Income / Direct Transfer Received
    addTx(
      ref: 'SH01AA1001',
      type: TransactionType.receiveMoney,
      classification: FinancialClassification.income,
      amountCents: 4500000, // KSh 45,000.00
      feeCents: 0,
      daysAgo: 12,
      hour: 9,
      minute: 15,
      counterpartyName: 'TECH LABS KENYA LTD',
      counterpartyPhone: '0712345678',
      categoryId: 'income',
      categoryName: 'Income & Earnings',
      description: 'Consulting Retainer Milestone 1',
      balanceAfterCents: 5245000,
    );

    // 2. Rent payment via PayBill
    addTx(
      ref: 'SH02BB2002',
      type: TransactionType.payBill,
      classification: FinancialClassification.expense,
      amountCents: 2000000, // KSh 20,000.00
      feeCents: 2500, // KSh 25.00
      daysAgo: 10,
      hour: 14,
      minute: 30,
      counterpartyName: 'GREENPARK HOMES',
      accountRef: 'HOUSE-B12',
      categoryId: 'rent',
      categoryName: 'Rent & Housing',
      description: 'Monthly Apartment Rent',
      balanceAfterCents: 3242500,
    );

    // 3. Supermarket Groceries - Buy Goods
    addTx(
      ref: 'SH03CC3003',
      type: TransactionType.buyGoods,
      classification: FinancialClassification.expense,
      amountCents: 435000, // KSh 4,350.00
      feeCents: 0,
      daysAgo: 8,
      hour: 18,
      minute: 45,
      counterpartyName: 'NAIVAS SUPERMARKET JUNCTION',
      accountRef: '654321',
      categoryId: 'food_groceries',
      categoryName: 'Food & Groceries',
      description: 'Weekly household supplies',
      balanceAfterCents: 2807500,
    );

    // 4. KPLC Electricity Token - PayBill
    addTx(
      ref: 'SH04DD4004',
      type: TransactionType.payBill,
      classification: FinancialClassification.expense,
      amountCents: 150000, // KSh 1,500.00
      feeCents: 2300, // KSh 23.00
      daysAgo: 7,
      hour: 10,
      minute: 20,
      counterpartyName: 'KPLC PREPAID',
      accountRef: '37194829104',
      categoryId: 'utilities',
      categoryName: 'Utilities & Bills',
      description: 'Electricity Tokens',
      balanceAfterCents: 2655200,
    );

    // 5. Fuel & Commute - Buy Goods
    addTx(
      ref: 'SH05EE5005',
      type: TransactionType.buyGoods,
      classification: FinancialClassification.expense,
      amountCents: 300000, // KSh 3,000.00
      feeCents: 0,
      daysAgo: 5,
      hour: 8,
      minute: 10,
      counterpartyName: 'TOTALENERGIES KILIMANI',
      accountRef: '789123',
      categoryId: 'transport',
      categoryName: 'Transport',
      description: 'Vehicle Refueling',
      balanceAfterCents: 2355200,
    );

    // 6. Airtime Purchase
    addTx(
      ref: 'SH06FF6006',
      type: TransactionType.airtime,
      classification: FinancialClassification.expense,
      amountCents: 50000, // KSh 500.00
      feeCents: 0,
      daysAgo: 4,
      hour: 12,
      minute: 0,
      counterpartyName: 'Safaricom Airtime',
      accountRef: '0722000000',
      categoryId: 'airtime_data',
      categoryName: 'Airtime & Internet',
      description: 'Airtime Recharge',
      balanceAfterCents: 2305200,
    );

    // 7. Send Money to Family
    addTx(
      ref: 'SH07GG7007',
      type: TransactionType.sendMoney,
      classification: FinancialClassification.transfer,
      amountCents: 250000, // KSh 2,500.00
      feeCents: 3400, // KSh 34.00
      daysAgo: 3,
      hour: 16,
      minute: 15,
      counterpartyName: 'MARY WANJIKU',
      counterpartyPhone: '0720123456',
      categoryId: 'transfers',
      categoryName: 'Transfers & Send Money',
      description: 'Upcountry Support',
      balanceAfterCents: 2051800,
    );

    // 8. Restaurant & Dining
    addTx(
      ref: 'SH08HH8008',
      type: TransactionType.buyGoods,
      classification: FinancialClassification.expense,
      amountCents: 185000, // KSh 1,850.00
      feeCents: 0,
      daysAgo: 2,
      hour: 13,
      minute: 40,
      counterpartyName: 'JAVA HOUSE VALLEY ARCADE',
      accountRef: '456789',
      categoryId: 'food_groceries',
      categoryName: 'Food & Groceries',
      description: 'Lunch & Coffee Meeting',
      balanceAfterCents: 1866800,
    );

    // 9. ATM / Agent Cash Withdrawal
    addTx(
      ref: 'SH09II9009',
      type: TransactionType.withdrawAgent,
      classification: FinancialClassification.withdrawal,
      amountCents: 500000, // KSh 5,000.00
      feeCents: 6700, // KSh 67.00
      daysAgo: 1,
      hour: 11,
      minute: 5,
      counterpartyName: 'AGENT 284910 - HURST ENTERPRISES',
      categoryId: 'cash_withdrawals',
      categoryName: 'Cash Withdrawals',
      description: 'Pocket Cash Withdrawal',
      balanceAfterCents: 1360100,
    );

    // 10. Streaming & Entertainment - PayBill
    addTx(
      ref: 'SH10JJ1010',
      type: TransactionType.payBill,
      classification: FinancialClassification.expense,
      amountCents: 110000, // KSh 1,100.00
      feeCents: 0,
      daysAgo: 0,
      hour: 19,
      minute: 30,
      counterpartyName: 'NETFLIX KENYA',
      accountRef: 'MEMBER-83921',
      categoryId: 'entertainment',
      categoryName: 'Entertainment',
      description: 'Standard Video Streaming Subscription',
      balanceAfterCents: 1250100,
    );

    return transactions;
  }

  /// Seeds sample transactions into SQLite database.
  /// Skips transactions that have already been seeded.
  /// Returns count of newly inserted records.
  static Future<int> seed({TransactionRepository? repository}) async {
    final repo = repository ?? TransactionRepository();
    final sampleTxs = getSampleTransactions();
    return await repo.insertBatch(sampleTxs);
  }
}
