import '../parser/mpesa_transaction_types.dart';

/// Transaction data model storing all financial event attributes.
/// Uses integer minor units (cents) to avoid floating-point inaccuracies.
class TransactionModel {
  final String id;
  final String? mpesaReference;
  final TransactionType transactionType;
  final FinancialClassification classification;
  final int amountCents;
  final int feeCents;
  final String currency;
  final DateTime timestamp;
  final DateTime? smsReceivedTimestamp;
  final String? counterpartyName;
  final String? counterpartyPhone;
  final String? accountReference;
  final String? description;
  final String categoryId;
  final String categoryName;
  final TransactionSource source;
  final String fingerprint;
  final ReviewStatus reviewStatus;
  final String? reversalReference;
  final int? balanceAfterCents;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TransactionModel({
    required this.id,
    this.mpesaReference,
    required this.transactionType,
    required this.classification,
    required this.amountCents,
    this.feeCents = 0,
    this.currency = 'KES',
    required this.timestamp,
    this.smsReceivedTimestamp,
    this.counterpartyName,
    this.counterpartyPhone,
    this.accountReference,
    this.description,
    required this.categoryId,
    required this.categoryName,
    required this.source,
    required this.fingerprint,
    this.reviewStatus = ReviewStatus.verified,
    this.reversalReference,
    this.balanceAfterCents,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Amount in Shillings (e.g. 150000 cents -> 1500.00 KSh).
  double get amountInShillings => amountCents / 100.0;

  /// Fee in Shillings.
  double get feeInShillings => feeCents / 100.0;

  /// Total outgoing amount including fees (if outgoing expense or transfer).
  int get totalOutgoingCents => amountCents + feeCents;

  double get totalOutgoingInShillings => totalOutgoingCents / 100.0;

  bool get isExpense => classification == FinancialClassification.expense;
  bool get isIncome => classification == FinancialClassification.income;
  bool get isTransfer => classification == FinancialClassification.transfer;
  bool get isWithdrawal => classification == FinancialClassification.withdrawal;
  bool get isDeposit => classification == FinancialClassification.deposit;
  bool get isReversal => classification == FinancialClassification.adjustment;

  TransactionModel copyWith({
    String? id,
    String? mpesaReference,
    TransactionType? transactionType,
    FinancialClassification? classification,
    int? amountCents,
    int? feeCents,
    String? currency,
    DateTime? timestamp,
    DateTime? smsReceivedTimestamp,
    String? counterpartyName,
    String? counterpartyPhone,
    String? accountReference,
    String? description,
    String? categoryId,
    String? categoryName,
    TransactionSource? source,
    String? fingerprint,
    ReviewStatus? reviewStatus,
    String? reversalReference,
    int? balanceAfterCents,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      mpesaReference: mpesaReference ?? this.mpesaReference,
      transactionType: transactionType ?? this.transactionType,
      classification: classification ?? this.classification,
      amountCents: amountCents ?? this.amountCents,
      feeCents: feeCents ?? this.feeCents,
      currency: currency ?? this.currency,
      timestamp: timestamp ?? this.timestamp,
      smsReceivedTimestamp: smsReceivedTimestamp ?? this.smsReceivedTimestamp,
      counterpartyName: counterpartyName ?? this.counterpartyName,
      counterpartyPhone: counterpartyPhone ?? this.counterpartyPhone,
      accountReference: accountReference ?? this.accountReference,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      source: source ?? this.source,
      fingerprint: fingerprint ?? this.fingerprint,
      reviewStatus: reviewStatus ?? this.reviewStatus,
      reversalReference: reversalReference ?? this.reversalReference,
      balanceAfterCents: balanceAfterCents ?? this.balanceAfterCents,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mpesa_reference': mpesaReference,
      'transaction_type': transactionType.name,
      'classification': classification.name,
      'amount_cents': amountCents,
      'fee_cents': feeCents,
      'currency': currency,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'sms_received_timestamp': smsReceivedTimestamp?.millisecondsSinceEpoch,
      'counterparty_name': counterpartyName,
      'counterparty_phone': counterpartyPhone,
      'account_reference': accountReference,
      'description': description,
      'category_id': categoryId,
      'category_name': categoryName,
      'source': source.name,
      'fingerprint': fingerprint,
      'review_status': reviewStatus.name,
      'reversal_reference': reversalReference,
      'balance_after_cents': balanceAfterCents,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String,
      mpesaReference: map['mpesa_reference'] as String?,
      transactionType: TransactionType.values.firstWhere(
        (e) => e.name == map['transaction_type'],
        orElse: () => TransactionType.unknown,
      ),
      classification: FinancialClassification.values.firstWhere(
        (e) => e.name == map['classification'],
        orElse: () => FinancialClassification.unclassified,
      ),
      amountCents: map['amount_cents'] as int,
      feeCents: (map['fee_cents'] as int?) ?? 0,
      currency: (map['currency'] as String?) ?? 'KES',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      smsReceivedTimestamp: map['sms_received_timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              map['sms_received_timestamp'] as int)
          : null,
      counterpartyName: map['counterparty_name'] as String?,
      counterpartyPhone: map['counterparty_phone'] as String?,
      accountReference: map['account_reference'] as String?,
      description: map['description'] as String?,
      categoryId: map['category_id'] as String,
      categoryName: map['category_name'] as String,
      source: TransactionSource.values.firstWhere(
        (e) => e.name == map['source'],
        orElse: () => TransactionSource.manual,
      ),
      fingerprint: map['fingerprint'] as String,
      reviewStatus: ReviewStatus.values.firstWhere(
        (e) => e.name == map['review_status'],
        orElse: () => ReviewStatus.verified,
      ),
      reversalReference: map['reversal_reference'] as String?,
      balanceAfterCents: map['balance_after_cents'] as int?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }
}
