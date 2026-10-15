import 'mpesa_parser_utils.dart';
import 'mpesa_transaction_types.dart';
import 'parsed_sms_result.dart';
import 'strategies/parsing_strategy.dart';

/// Main M-Pesa SMS parsing engine.
/// Coordinates specialized parsing strategies, validates extracted data,
/// and flags ambiguous messages for user review.
class MpesaParser {
  final List<ParsingStrategy> _strategies;

  MpesaParser({List<ParsingStrategy>? strategies})
      : _strategies = strategies ??
            [
              ReversalStrategy(),
              PayBillStrategy(),
              BuyGoodsStrategy(),
              AirtimeStrategy(),
              SendMoneyStrategy(),
              ReceiveMoneyStrategy(),
              WithdrawStrategy(),
              DepositStrategy(),
            ];

  /// Tests whether the text looks like an M-Pesa SMS.
  bool isProbableMpesaSms(String message) {
    if (message.trim().isEmpty) return false;

    // Must have Confirmed/confirmed and Ksh/KES/balance
    final hasConfirmed =
        RegExp(r'\bconfirmed\b', caseSensitive: false).hasMatch(message);
    final hasCurrency =
        RegExp(r'\b(?:Ksh|KES)\b', caseSensitive: false).hasMatch(message);
    final hasReference = RegExp(r'^[A-Z0-9]{8,12}\s+', caseSensitive: false)
        .hasMatch(message.trim());

    return (hasConfirmed && hasCurrency) || (hasConfirmed && hasReference);
  }

  /// Parses an incoming SMS message.
  ParsedSmsResult parse(String rawMessage) {
    final cleanMessage = rawMessage.trim();
    if (cleanMessage.isEmpty) {
      return ParsedSmsResult.unrecognized(rawMessage, reason: 'Empty message');
    }

    if (!isProbableMpesaSms(cleanMessage)) {
      return ParsedSmsResult.unrecognized(
        rawMessage,
        reason: 'Message does not match M-Pesa confirmation structure',
      );
    }

    for (final strategy in _strategies) {
      if (strategy.canParse(cleanMessage)) {
        try {
          final result = strategy.parse(cleanMessage);

          // Validation checks
          if (result.amountCents <= 0) {
            return ParsedSmsResult(
              isMpesa: true,
              mpesaReference: result.mpesaReference,
              transactionType: result.transactionType,
              classification: result.classification,
              amountCents: 0,
              confidenceScore: 0.3,
              reviewStatus: ReviewStatus.needsReview,
              failureReason: 'Extracted amount is zero or negative',
              rawMessage: rawMessage,
            );
          }

          return result;
        } catch (e) {
          return ParsedSmsResult(
            isMpesa: true,
            mpesaReference:
                MpesaParserUtils.extractMpesaReference(cleanMessage),
            transactionType: TransactionType.unknown,
            classification: FinancialClassification.unclassified,
            amountCents: 0,
            confidenceScore: 0.1,
            reviewStatus: ReviewStatus.needsReview,
            failureReason: 'Exception during strategy parsing: $e',
            rawMessage: rawMessage,
          );
        }
      }
    }

    // Fallback: If it has reference and Confirmed, but no strategy matched
    final ref = MpesaParserUtils.extractMpesaReference(cleanMessage);
    final amountCents = MpesaParserUtils.parseAmountToCents(cleanMessage) ?? 0;
    final timestamp = MpesaParserUtils.parseDateTime(cleanMessage);

    return ParsedSmsResult(
      isMpesa: true,
      mpesaReference: ref,
      transactionType: TransactionType.unknown,
      classification: FinancialClassification.unclassified,
      amountCents: amountCents,
      timestamp: timestamp,
      confidenceScore: 0.4,
      reviewStatus: ReviewStatus.needsReview,
      failureReason: 'Unsupported M-Pesa transaction format',
      rawMessage: rawMessage,
    );
  }
}
