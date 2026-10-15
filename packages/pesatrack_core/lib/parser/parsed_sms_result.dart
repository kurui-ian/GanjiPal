import 'mpesa_transaction_types.dart';

/// Structured result of parsing an SMS message.
class ParsedSmsResult {
  final bool isMpesa;
  final String? mpesaReference;
  final TransactionType transactionType;
  final FinancialClassification classification;
  final int amountCents;
  final int feeCents;
  final DateTime? timestamp;
  final String? counterpartyName;
  final String? counterpartyPhone;
  final String? accountReference;
  final String? description;
  final int? balanceAfterCents;
  final String? reversalReference;
  final double confidenceScore;
  final ReviewStatus reviewStatus;
  final String? failureReason;
  final String rawMessage;

  const ParsedSmsResult({
    required this.isMpesa,
    this.mpesaReference,
    required this.transactionType,
    required this.classification,
    required this.amountCents,
    this.feeCents = 0,
    this.timestamp,
    this.counterpartyName,
    this.counterpartyPhone,
    this.accountReference,
    this.description,
    this.balanceAfterCents,
    this.reversalReference,
    this.confidenceScore = 1.0,
    this.reviewStatus = ReviewStatus.verified,
    this.failureReason,
    required this.rawMessage,
  });

  double get amountInShillings => amountCents / 100.0;
  double get feeInShillings => feeCents / 100.0;

  factory ParsedSmsResult.unrecognized(String rawMessage, {String? reason}) {
    return ParsedSmsResult(
      isMpesa: false,
      transactionType: TransactionType.unknown,
      classification: FinancialClassification.unclassified,
      amountCents: 0,
      confidenceScore: 0.0,
      reviewStatus: ReviewStatus.needsReview,
      failureReason: reason ?? 'Unrecognized M-Pesa format',
      rawMessage: rawMessage,
    );
  }
}
